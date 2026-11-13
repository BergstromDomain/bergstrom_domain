# spec/models/dossier/assignment_spec.rb
require "rails_helper"

RSpec.describe Dossier::Assignment, type: :model do
  include ActiveSupport::Testing::TimeHelpers

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
    it { is_expected.to have_db_column(:position).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:deleted_at).of_type(:datetime) }
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
    it "Is soft-deleted: hidden from its Engagement's Assignments, kept for 30 days, and restorable" do
      assignment = create(:dossier_assignment, engagement: engagement)
      freeze_time do
        assignment.soft_delete!
        expect(assignment).to have_attributes(deleted_at: Time.current, purge_at: 30.days.from_now)
      end

      expect(engagement.reload.assignments).to be_empty
      expect(engagement.all_assignments).to contain_exactly(assignment)
      expect(Dossier::Assignment.discarded).to contain_exactly(assignment)

      assignment.restore!
      expect(engagement.reload.assignments).to contain_exactly(assignment)
      expect(Dossier::Assignment.kept).to contain_exactly(assignment)
    end

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

    it "Is titled 'Client - Project' with the client's full name on its own page" do
      assignment = build(:dossier_assignment, engagement: engagement, project: "Energy Components Upgrade",
                                              client: build(:dossier_organisation, name: "APA Group", abbreviation: "APA"))
      expect(assignment.title).to eq("APA Group - Energy Components Upgrade")
    end

    it "Is headed 'Client - Project' on the Timeline" do
      assignment = build(:dossier_assignment, engagement: engagement, project: "  Market Services ",
                                              client: build(:dossier_organisation, name: "Northwind"))
      expect(assignment.heading).to eq("Northwind - Market Services")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is hidden when it's deleted, or when its Engagement is" do
      assignment = create(:dossier_assignment, engagement: engagement)
      expect(assignment).not_to be_hidden

      engagement.soft_delete!
      expect(assignment.reload).to be_hidden
      engagement.restore!
      assignment.soft_delete!
      expect(assignment.reload).to be_hidden
    end

    it "Hides its Achievements and Training while it's deleted" do
      assignment  = create(:dossier_assignment, engagement: engagement)
      achievement = create(:dossier_achievement, assignment: assignment)
      course      = create(:dossier_credential, user: engagement.user, engagement: engagement, assignment: assignment)
      assignment.soft_delete!

      expect(achievement.reload).to be_hidden
      expect(course.reload).to be_hidden
      expect(Dossier::Credential.kept).not_to include(course)
    end

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

    it "Is titled by the client's full name alone when it has no Project" do
      assignment = build(:dossier_assignment, engagement: engagement, project: nil,
                                              client: build(:dossier_organisation, name: "APA Group", abbreviation: "APA"))
      expect(assignment.title).to eq("APA Group")
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

    it "Doesn't let a deleted Assignment stop its Engagement's dates changing" do
      assignment = create(:dossier_assignment, engagement: engagement, start_month: "2019-03", end_month: "2022-06")
      assignment.soft_delete!
      expect(engagement.reload.update(end_month: "2020-01")).to be true
      expect(assignment.reload.fits_within?(engagement)).to be false
    end

    it "Orders an Engagement's Assignments newest first" do
      first  = create(:dossier_assignment, engagement: engagement, start_month: "2019-03", end_month: "2020-01")
      second = create(:dossier_assignment, engagement: engagement, start_month: "2020-02", end_month: "2022-06")
      expect(engagement.assignments.newest_first.to_a).to eq([ second, first ])
    end
  end

  # ── Sort order within the Engagement ──────────────────────────────────────
  describe "Sort order" do
    def assignment(month) = create(:dossier_assignment, engagement: engagement, start_month: month, end_month: month)
    def order = engagement.reload.assignments.to_a

    # 1) Happy Path ──────────────────────────────────────────────────────────
    it "Moves an Assignment up and down past its neighbour" do
      first, second, third = assignment("2019-03"), assignment("2020-01"), assignment("2021-01")
      expect(order).to eq([ third, second, first ])

      expect(first.move!(:up)).to be(true)
      expect(order).to eq([ third, first, second ])
      expect(third.move!(:down)).to be(true)
      expect(order).to eq([ first, third, second ])
    end

    # 2) Negative Path ───────────────────────────────────────────────────────
    it "Leaves the top Assignment when moved up, and the bottom one when moved down" do
      older, newer = assignment("2019-03"), assignment("2020-01")

      expect(newer.move!(:up)).to be(false)
      expect(older.move!(:down)).to be(false)
      expect(order).to eq([ newer, older ])
    end

    # 3) Alternative Path ────────────────────────────────────────────────────
    it "Puts a new Assignment at the top, even when it's older" do
      newer = assignment("2021-01")
      older = assignment("2019-03")
      expect(order).to eq([ older, newer ])
    end

    it "Gives a permanent job's automatic Assignment a position" do
      permanent = create(:dossier_engagement, :permanent)
      expect(permanent.assignments.first.position).to be_present
    end

    # 4) Edge Cases ──────────────────────────────────────────────────────────
    it "Skips a deleted Assignment when moving" do
      first, second, third = assignment("2019-03"), assignment("2020-01"), assignment("2021-01")
      second.soft_delete!

      expect(first.move!(:up)).to be(true)
      expect(order).to eq([ first, third ])
    end

    it "Moves only within its own Engagement" do
      own = assignment("2019-03")
      create(:dossier_assignment, engagement: create(:dossier_engagement, start_month: "2019-03", end_month: "2022-06"))
      expect(own.move!(:up)).to be(false)
    end
  end
end
