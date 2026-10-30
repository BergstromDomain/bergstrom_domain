# spec/services/dossier/timeline_spec.rb
require "rails_helper"

RSpec.describe Dossier::Timeline do
  let(:user) { create(:user, :content_creator) }

  def engagement(start_month, end_month, **attributes)
    create(:dossier_engagement, user: user, start_month: start_month, end_month: end_month, **attributes)
  end

  def assignment(engagement, start_month, end_month)
    create(:dossier_assignment, engagement: engagement, start_month: start_month, end_month: end_month)
  end

  def timeline = described_class.new(user.dossier_engagements.kept, today: Date.new(2026, 10, 30))

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Lists Engagements newest first with the gaps between them" do
      older = engagement("2015-01", "2017-12")
      newer = engagement("2018-06", "2022-06")

      entries = timeline.entries
      expect(entries.map(&:kind)).to eq(%i[engagement gap engagement])
      expect(entries.map(&:engagement).compact).to eq([ newer, older ])
      gap = entries[1]
      expect([ gap.date_range, gap.duration ]).to eq([ "Jan 2018 – May 2018", "5 months" ])
    end

    it "Shows bench time inside an Engagement between its Assignments" do
      consultancy = engagement("2019-01", "2020-12")
      assignment(consultancy, "2019-01", "2019-06")
      assignment(consultancy, "2019-10", "2020-12")

      bench = timeline.entries.first.bench
      expect(bench.map(&:date_range)).to eq([ "Jul 2019 – Sep 2019" ])
      expect(bench.first.duration).to eq("3 months")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows no gap between back-to-back Engagements" do
      engagement("2015-01", "2017-12")
      engagement("2018-01", "2022-06")
      expect(timeline.entries.map(&:kind)).to eq(%i[engagement engagement])
    end

    it "Shows no bench time for a permanent job" do
      engagement("2019-01", "2020-12", employment_type: create(:dossier_employment_type, :permanent))
      expect(timeline.entries.first.bench).to be_empty
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Treats a whole Engagement without Assignments as bench time" do
      engagement("2004-01", "2005-01")
      bench = timeline.entries.first.bench
      expect([ bench.first.date_range, bench.first.duration ]).to eq([ "Jan 2004 – Jan 2005", "1+ year" ])
    end

    it "Runs a current Engagement's bench time up to today" do
      current = engagement("2025-01", "")
      assignment(current, "2025-01", "2025-12")
      expect(timeline.entries.first.bench.map(&:date_range)).to eq([ "Jan 2026 – Oct 2026" ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Merges overlapping Engagements before looking for gaps" do
      engagement("2010-01", "2015-12")
      engagement("2012-01", "2013-12")
      engagement("2017-01", "2018-12")
      expect(timeline.entries.count { |e| e.kind == :gap }).to eq(1)
      expect(timeline.entries.find { |e| e.kind == :gap }.date_range).to eq("Jan 2016 – Dec 2016")
    end

    it "Formats durations: under a month, months, then whole years" do
      expect(described_class.duration(Date.new(2020, 1, 1), Date.new(2020, 1, 10))).to eq("Under a month")
      expect(described_class.duration(Date.new(2020, 1, 1), Date.new(2020, 1, 31))).to eq("1 month")
      expect(described_class.duration(Date.new(2020, 1, 1), Date.new(2021, 12, 31))).to eq("2+ years")
    end

    it "Is empty without Engagements" do
      expect(timeline.entries).to be_empty
    end
  end
end
