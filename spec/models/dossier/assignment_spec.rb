# spec/models/dossier/assignment_spec.rb
require "rails_helper"

RSpec.describe Dossier::Assignment, type: :model do
  let(:engagement) { create(:dossier_engagement, start_month: "2019-03", end_month: "2022-06") }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:engagement_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:client_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:role_id).of_type(:integer) }
    it { is_expected.to have_db_column(:location_id).of_type(:integer) }
    it { is_expected.to have_db_column(:remote).of_type(:boolean).with_options(null: false, default: false) }
    it { is_expected.to have_db_column(:start_on).of_type(:date).with_options(null: false) }
    it { is_expected.to have_db_column(:end_on).of_type(:date) }
    it { is_expected.to have_db_column(:summary).of_type(:text) }
    it { is_expected.to have_db_column(:project).of_type(:string) }
    it { is_expected.to have_db_column(:classification).of_type(:string).with_options(null: false, default: "restricted") }
    it { is_expected.to have_db_column(:position).of_type(:integer) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:engagement) }
    it { is_expected.to belong_to(:client).class_name("Dossier::Organisation") }
    it { is_expected.to belong_to(:role).optional }
    it { is_expected.to belong_to(:location).optional }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is valid within its Engagement's dates, owned by the Engagement's user" do
      assignment = create(:dossier_assignment, engagement: engagement)
      expect(assignment).to be_valid
      expect(assignment.user).to eq(engagement.user)
    end

    it "Is labelled 'Role at Client'" do
      assignment = build(:dossier_assignment, engagement: engagement,
                                              role: build(:dossier_role, name: "Test Manager"),
                                              client: build(:dossier_organisation, name: "Northwind"))
      expect(assignment.to_toast_label).to eq("Test Manager at Northwind")
    end

    it "Is headed 'Client - Project' on the Timeline" do
      assignment = build(:dossier_assignment, engagement: engagement, project: "  Market Services ",
                                              client: build(:dossier_organisation, name: "Northwind"))
      expect(assignment.heading).to eq("Northwind - Market Services")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid when it starts before its Engagement" do
      assignment = build(:dossier_assignment, engagement: engagement, start_month: "2019-02")
      expect(assignment).not_to be_valid
      expect(assignment.errors[:start_month]).to include("must not be before the Engagement starts (Mar 2019)")
    end

    it "Is invalid when it ends after its Engagement" do
      assignment = build(:dossier_assignment, engagement: engagement, end_month: "2022-07")
      expect(assignment).not_to be_valid
      expect(assignment.errors[:end_month]).to include("must not be after the Engagement ends (Jun 2022)")
    end

    it "Is invalid when it's current but its Engagement has ended" do
      assignment = build(:dossier_assignment, engagement: engagement, end_month: "")
      expect(assignment).not_to be_valid
      expect(assignment.errors[:end_month]).to include("must not be after the Engagement ends (Jun 2022)")
    end

    it "Is invalid without a client" do
      assignment = build(:dossier_assignment, engagement: engagement, client: nil)
      expect(assignment).not_to be_valid
      expect(assignment.errors[:client]).to include("must exist")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Is headed by the client alone when it has no Project" do
      assignment = build(:dossier_assignment, engagement: engagement, project: " ",
                                              role: build(:dossier_role, name: "Test Manager"),
                                              client: build(:dossier_organisation, name: "Northwind"))
      expect(assignment.project).to be_nil
      expect(assignment.heading).to eq("Northwind")
    end

    it "Heads the row with the client's abbreviation when it has one" do
      assignment = build(:dossier_assignment, project: "Digital Licencing",
                                              client: build(:dossier_organisation, name: "Northwind Transport Authority", abbreviation: "NTA"))
      expect(assignment.heading).to eq("NTA - Digital Licencing")
    end

    it "Uses the Engagement's position title when it has no Role" do
      assignment = build(:dossier_assignment, engagement: engagement, role: nil,
                                              client: build(:dossier_organisation, name: "Northwind"))
      expect(assignment.role_name).to eq("Test Consultant")
      expect(assignment.to_toast_label).to eq("Test Consultant at Northwind")
    end

    it "Can run on while a current Engagement runs on" do
      current = create(:dossier_engagement, :current, start_month: "2024-08")
      expect(build(:dossier_assignment, engagement: current, end_month: "")).to be_valid
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Fits a day-precision end inside a month-precision Engagement end" do
      expect(build(:dossier_assignment, engagement: engagement, end_month: "2022-06", end_day: "30")).to be_valid
    end

    it "Orders an Engagement's Assignments newest first" do
      first  = create(:dossier_assignment, engagement: engagement, start_month: "2019-03", end_month: "2020-01")
      second = create(:dossier_assignment, engagement: engagement, start_month: "2020-02", end_month: "2022-06")
      expect(engagement.assignments.newest_first.to_a).to eq([ second, first ])
    end
  end
end
