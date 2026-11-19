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

  # A permanent job without the Assignment it gets on create, so the test
  # chooses which stretches its Assignments cover.
  def permanent(start_month, end_month)
    engagement(start_month, end_month, employment_type: create(:dossier_employment_type, :permanent)).tap do |job|
      job.assignments.each(&:destroy!)
      job.assignments.reset
    end
  end

  def timeline = described_class.new(user.dossier_engagements.kept, today: Date.new(2026, 10, 30))

  # PinnacleQM's shape: a contract with EIP, then TMR, and Hudson between them.
  def split_contract
    contract = engagement("2018-11", "2023-01")
    eip = assignment(contract, "2018-11", "2019-08")
    tmr = assignment(contract, "2020-09", "2023-01")
    hudson = engagement("2019-12", "2020-09")
    [ contract, eip, tmr, hudson ]
  end

  def cards(entries = timeline.entries) = entries.select { |entry| entry.kind == :engagement }

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

    it "Shows bench time inside a permanent job between its Assignments" do
      consultancy = permanent("2019-01", "2020-12")
      assignment(consultancy, "2019-01", "2019-06")
      assignment(consultancy, "2019-10", "2020-12")

      bench = timeline.entries.first.bench
      expect(bench.map(&:date_range)).to eq([ "Jul 2019 – Sep 2019" ])
      expect(bench.first.duration).to eq("3 months")
    end

    it "Splits a contract into one card per run of Assignments around another Engagement" do
      contract, eip, tmr, hudson = split_contract

      shown = cards
      expect(shown.map(&:engagement)).to eq([ contract, hudson, contract ])
      expect(shown.map(&:date_range)).to eq([ "Sep 2020 – Jan 2023", "Dec 2019 – Sep 2020", "Nov 2018 – Aug 2019" ])
      expect([ shown.first.assignments, shown.last.assignments ]).to eq([ [ tmr ], [ eip ] ])
    end

    it "Shows the time between a split card and the other Engagement as a gap" do
      split_contract
      gaps = timeline.entries.select { |entry| entry.kind == :gap }
      expect(gaps.map { |gap| [ gap.date_range, gap.duration ] }).to eq([ [ "Sep 2019 – Nov 2019", "3 months" ] ])
    end

    it "Names the other Engagements between a split Engagement's runs" do
      contract, _eip, _tmr, hudson = split_contract

      others = described_class.other_engagements_for(contract, today: Date.new(2026, 10, 30))
      expect(others.map { |other| [ other.period.date_range, other.engagements ] }).to eq([ [ "Sep 2019 – Aug 2020", [ hudson ] ] ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows no gap between back-to-back Engagements" do
      engagement("2015-01", "2017-12")
      engagement("2018-01", "2022-06")
      expect(timeline.entries.map(&:kind)).to eq(%i[engagement engagement])
    end

    it "Shows no bench time for a permanent job its Assignment covers" do
      engagement("2019-01", "2020-12", employment_type: create(:dossier_employment_type, :permanent))
      expect(timeline.entries.first.bench).to be_empty
    end

    it "Shows no bench time for a Contractor between its Assignments" do
      contract = engagement("2018-11", "2023-01")
      assignment(contract, "2018-11", "2019-08")
      assignment(contract, "2020-09", "2023-01")

      expect(timeline.entries.first.bench).to be_empty
      expect(described_class.bench_for(contract)).to be_empty
    end

    it "Doesn't split a contract with nothing else between its Assignments" do
      contract = engagement("2018-11", "2023-01")
      assignment(contract, "2018-11", "2019-08")
      assignment(contract, "2020-09", "2023-01")

      expect(timeline.entries.map(&:kind)).to eq(%i[engagement])
      expect(timeline.entries.first.assignments).to be_nil # a whole card shows them all
      expect(described_class.other_engagements_for(contract)).to be_empty
    end

    it "Never splits a permanent job" do
      consultancy = permanent("2018-11", "2023-01")
      assignment(consultancy, "2018-11", "2019-08")
      assignment(consultancy, "2020-09", "2023-01")
      engagement("2019-12", "2020-06")

      expect(cards.map(&:engagement).count(consultancy)).to eq(1)
      expect(cards.first.bench.map(&:date_range)).to eq([ "Sep 2019 – Aug 2020" ])
    end

    it "Doesn't split around a personal Engagement or a career break" do
      contract = engagement("2018-11", "2023-01")
      assignment(contract, "2018-11", "2019-08")
      assignment(contract, "2020-09", "2023-01")
      engagement("2019-10", "2019-12", employment_type: create(:dossier_employment_type, :personal))
      create(:dossier_engagement, :career_break, user: user, start_month: "2020-01", end_month: "2020-03")

      expect(cards.map(&:engagement).count(contract)).to eq(1)
    end

    it "Never lets a career break fill a gap or have bench time" do
      engagement("2010-01", "2012-09")
      time_off = create(:dossier_engagement, :career_break, user: user, start_month: "2012-10", end_month: "2013-04")
      engagement("2013-05", "2018-11")

      entries = timeline.entries
      expect(entries.map(&:kind)).to eq(%i[engagement engagement gap engagement])
      expect(entries.find { |entry| entry.engagement == time_off }.bench).to be_empty
      expect(entries.find { |entry| entry.kind == :gap }.date_range).to eq("Oct 2012 – Apr 2013")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Lists a personal Engagement but never lets it fill a gap or have bench time" do
      engagement("2015-01", "2017-12")
      hobby = engagement("2017-06", "2018-12", employment_type: create(:dossier_employment_type, :personal))
      engagement("2018-06", "2022-06")

      entries = timeline.entries
      expect(entries.map(&:kind)).to eq(%i[engagement engagement gap engagement])
      expect(entries.find { |entry| entry.engagement == hobby }.bench).to be_empty
      expect(entries.find { |entry| entry.kind == :gap }.date_range).to eq("Jan 2018 – May 2018")
    end

    it "Treats a whole permanent job without Assignments as bench time" do
      permanent("2004-01", "2005-01")
      bench = timeline.entries.first.bench
      expect([ bench.first.date_range, bench.first.duration ]).to eq([ "Jan 2004 – Jan 2005", "1+ year" ])
    end

    it "Runs a current Engagement's bench time up to today" do
      current = permanent("2025-01", "")
      assignment(current, "2025-01", "2025-12")
      expect(timeline.entries.first.bench.map(&:date_range)).to eq([ "Jan 2026 – Oct 2026" ])
    end

    it "Splits into three cards around two other Engagements" do
      contract = engagement("2010-01", "2015-12")
      runs = [ %w[2010-01 2010-12], %w[2012-01 2012-12], %w[2014-01 2015-12] ].map { |from, to| assignment(contract, from, to) }
      engagement("2011-02", "2011-10")
      engagement("2013-03", "2013-09")

      mine = cards.select { |card| card.engagement == contract }
      expect(mine.map(&:assignments)).to eq(runs.reverse.map { |run| [ run ] })
      expect(mine.map(&:date_range)).to eq([ "Jan 2014 – Dec 2015", "Jan 2012 – Dec 2012", "Jan 2010 – Dec 2010" ])
    end

    it "Places each bench above the first Assignment, in list order, that ended before it" do
      qpt = Data.define(:start_on, :effective_end).new(Date.new(2024, 9, 1), Date.new(2025, 5, 31))
      dl  = Data.define(:start_on, :effective_end).new(Date.new(2025, 8, 1), nil)
      bench = described_class::Period.new(from: Date.new(2025, 6, 1), to: Date.new(2025, 7, 31))
      early = described_class::Period.new(from: Date.new(2024, 1, 1), to: Date.new(2024, 8, 31))

      expect(described_class.interleave([ dl, qpt ], [ bench ])).to eq([ dl, bench, qpt ])
      expect(described_class.interleave([ dl, qpt ], [ early, bench ])).to eq([ dl, bench, qpt, early ])
      expect(described_class.interleave([ qpt, dl ], [ bench ])).to eq([ bench, qpt, dl ])
      expect(described_class.interleave([], [ early, bench ])).to eq([ bench, early ])
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

    it "Shows a one-month gap as just that month" do
      engagement("2010-01", "2015-12")
      engagement("2016-02", "2018-12")
      expect(timeline.entries.find { |e| e.kind == :gap }.date_range).to eq("Jan 2016")
    end

    it "Formats durations: under a month, months, then whole years" do
      expect(described_class.duration(Date.new(2020, 1, 1), Date.new(2020, 1, 10))).to eq("Under a month")
      expect(described_class.duration(Date.new(2020, 1, 1), Date.new(2020, 1, 31))).to eq("1 month")
      expect(described_class.duration(Date.new(2020, 1, 1), Date.new(2021, 12, 31))).to eq("2+ years")
    end

    it "Finds a bench or gap period by its dates, with the Engagement a bench belongs to" do
      older = permanent("2015-01", "2017-12")
      assignment(older, "2015-01", "2017-06")
      engagement("2018-06", "2022-06")

      bench = timeline.period(Date.new(2017, 7, 1), Date.new(2017, 12, 31))
      gap   = timeline.period(Date.new(2018, 1, 1), Date.new(2018, 5, 31))
      expect([ bench.kind, bench.engagement ]).to eq([ :bench, older ])
      expect([ gap.kind, gap.engagement, gap.duration ]).to eq([ :gap, nil, "5 months" ])
      expect(timeline.period(Date.new(2018, 1, 1), Date.new(2018, 4, 30))).to be_nil
    end

    it "Splits when the other Engagement only partly overlaps the space between runs" do
      _contract, _eip, _tmr, hudson = split_contract
      hudson.update!(start_month: "2020-03", end_month: "2021-06")

      expect(cards.map(&:date_range)).to include("Nov 2018 – Aug 2019")
      expect(timeline.entries.select { |entry| entry.kind == :gap }.map(&:date_range)).to eq([ "Sep 2019 – Feb 2020" ])
    end

    it "Starts the first split card at the Engagement's start and ends the last at its end" do
      contract = engagement("2018-06", "2023-06")
      assignment(contract, "2018-11", "2019-08")
      assignment(contract, "2020-09", "2023-01")
      engagement("2019-12", "2020-06")

      mine = cards.select { |card| card.engagement == contract }
      expect(mine.map(&:date_range)).to eq([ "Sep 2020 – Jun 2023", "Jun 2018 – Aug 2019" ])
    end

    it "Doesn't split around Assignments that overlap" do
      contract = engagement("2018-01", "2020-12")
      assignment(contract, "2018-01", "2019-12")
      assignment(contract, "2019-06", "2020-12")
      engagement("2019-07", "2019-09")

      expect(cards.map(&:engagement).count(contract)).to eq(1)
    end

    it "Runs a current split Engagement's last card to today" do
      contract = engagement("2018-11", "")
      assignment(contract, "2018-11", "2019-08")
      assignment(contract, "2020-09", "")
      engagement("2019-12", "2020-06")

      expect(cards.first.date_range).to eq("Sep 2020 – Oct 2026")
    end

    it "Is empty without Engagements" do
      expect(timeline.entries).to be_empty
    end
  end
end
