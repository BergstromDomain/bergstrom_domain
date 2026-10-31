# spec/models/dossier/engagement_spec.rb
require "rails_helper"

RSpec.describe Dossier::Engagement, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:employer_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:employment_type_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:position_title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:start_on).of_type(:date).with_options(null: false) }
    it { is_expected.to have_db_column(:start_precision).of_type(:string).with_options(null: false, default: "month") }
    it { is_expected.to have_db_column(:end_on).of_type(:date) }
    it { is_expected.to have_db_column(:end_precision).of_type(:string).with_options(null: false, default: "month") }
    it { is_expected.to have_db_column(:summary).of_type(:text) }
    it { is_expected.to have_db_column(:classification).of_type(:string).with_options(null: false, default: "restricted") }
    it { is_expected.to have_db_column(:deleted_at).of_type(:datetime) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:employer).class_name("Dossier::Organisation") }
    it { is_expected.to belong_to(:employment_type) }
    it { is_expected.to have_many(:assignments).dependent(:destroy) }

    it "Keeps an Organisation from being deleted while it employs someone" do
      engagement = create(:dossier_engagement)
      expect(engagement.employer.destroy).to be(false)
    end
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is valid with an employer, employment type, position and start" do
      expect(build(:dossier_engagement)).to be_valid
    end

    it "Is Private by default, labelled 'Position at Employer'" do
      engagement = build(:dossier_engagement, position_title: "Test Manager",
                                              employer: build(:dossier_organisation, name: "Consultancy A"))
      expect(engagement.classification).to eq("restricted")
      expect(engagement.to_toast_label).to eq("Test Manager at Consultancy A")
    end

    it "Gives a permanent job one Assignment with the employer as client and the same dates" do
      engagement = create(:dossier_engagement, :permanent)
      expect(engagement.assignments.count).to eq(1)
      assignment = engagement.assignments.first
      expect(assignment.client).to eq(engagement.employer)
      expect([ assignment.start_on, assignment.end_on ]).to eq([ engagement.start_on, engagement.end_on ])
      expect(assignment.role).to be_nil
    end

    it "Takes dates as a month and an optional day" do
      engagement = build(:dossier_engagement, start_month: "2019-03", start_day: "15", end_month: "2022-06", end_day: "")
      expect([ engagement.start_on, engagement.start_precision ]).to eq([ Date.new(2019, 3, 15), "day" ])
      expect([ engagement.end_on, engagement.end_precision ]).to eq([ Date.new(2022, 6, 1), "month" ])
      expect([ engagement.start_month, engagement.start_day, engagement.end_day ]).to eq([ "2019-03", "15", nil ])
    end

    it "Formats its dates to their precision" do
      engagement = build(:dossier_engagement, start_month: "2019-03", start_day: "15", end_month: "2022-06")
      expect(engagement.date_range).to eq("15 Mar 2019 – Jun 2022")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid without a position title" do
      engagement = build(:dossier_engagement, position_title: " ")
      expect(engagement).not_to be_valid
      expect(engagement.errors[:position_title]).to include("can't be blank")
    end

    it "Is invalid without a start" do
      engagement = build(:dossier_engagement, start_month: "")
      expect(engagement).not_to be_valid
      expect(engagement.errors[:start_month]).to include("can't be blank")
    end

    it "Is invalid when it ends before it starts" do
      engagement = build(:dossier_engagement, start_month: "2019-03", end_month: "2019-02")
      expect(engagement).not_to be_valid
      expect(engagement.errors[:end_month]).to include("must not be before the start")
    end

    it "Is invalid with a day that doesn't exist in the month" do
      engagement = build(:dossier_engagement, start_month: "2019-02", start_day: "30")
      expect(engagement).not_to be_valid
      expect(engagement.errors[:start_day]).to include("is not a day in that month")
    end

    it "Is invalid with a month that doesn't exist, or a year without a month" do
      [ { start_month: "2019-13" }, { start_year: "2019", start_month_number: "" }, { start_year: "19", start_month_number: "5" } ].each do |dates|
        engagement = build(:dossier_engagement, **dates)
        expect(engagement).not_to be_valid
        expect(engagement.errors[:start_month]).to include("needs a four-digit year and a month, e.g. 2019 and May")
      end
    end

    it "Is invalid when a date change would leave an Assignment outside it" do
      engagement = create(:dossier_engagement, start_month: "2019-03", end_month: "2022-06")
      create(:dossier_assignment, engagement: engagement, start_month: "2019-03", end_month: "2020-01")
      engagement.start_month = "2019-06"
      expect(engagement).not_to be_valid
      expect(engagement.errors[:base]).to include("Every Assignment must fall within the Engagement's dates")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Is current when it has no end, shown as Present" do
      engagement = build(:dossier_engagement, :current, start_month: "2024-08")
      expect(engagement).to be_current
      expect(engagement.date_range).to eq("Aug 2024 – Present")
    end

    it "Takes a month as a year and a month number, as the form sends them" do
      engagement = build(:dossier_engagement, start_year: "2019", start_month_number: "5")
      expect(engagement.start_on).to eq(Date.new(2019, 5, 1))
      expect([ engagement.start_month, engagement.start_year, engagement.start_month_number ]).to eq([ "2019-05", "2019", "5" ])
    end

    it "Moves a permanent job's Assignment along with its dates" do
      engagement = create(:dossier_engagement, :permanent, start_month: "2019-03", end_month: "2022-06")
      engagement.update!(start_month: "2019-01", end_month: "2022-09")
      expect(engagement.assignments.first.date_range).to eq("Jan 2019 – Sep 2022")
    end

    it "Gives a non-permanent job no Assignment of its own" do
      expect(create(:dossier_engagement).assignments).to be_empty
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Treats a month-precision end as the whole month" do
      engagement = build(:dossier_engagement, start_month: "2019-03", end_month: "2019-03")
      expect(engagement).to be_valid
      expect(engagement.effective_end).to eq(Date.new(2019, 3, 31))
    end

    it "Allows a one-day engagement" do
      expect(build(:dossier_engagement, start_month: "2019-03", start_day: "15", end_month: "2019-03", end_day: "15")).to be_valid
    end

    it "Soft-deletes: hidden from .kept, restorable" do
      engagement = create(:dossier_engagement)
      engagement.soft_delete!
      expect(described_class.kept).not_to include(engagement)
      engagement.restore!
      expect(described_class.kept).to include(engagement)
    end

    it "Orders newest first, current ones on top" do
      old     = create(:dossier_engagement, start_month: "2010-01", end_month: "2012-01")
      current = create(:dossier_engagement, :current, start_month: "2015-01")
      recent  = create(:dossier_engagement, start_month: "2019-01", end_month: "2021-01")
      expect(described_class.newest_first.to_a).to eq([ current, recent, old ])
    end
  end
end
