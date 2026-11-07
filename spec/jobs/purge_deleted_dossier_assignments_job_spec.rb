# spec/jobs/purge_deleted_dossier_assignments_job_spec.rb
require "rails_helper"

RSpec.describe PurgeDeletedDossierAssignmentsJob, type: :job do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Permanently destroys an Assignment deleted more than 30 days ago, with its Achievements" do
      assignment  = create(:dossier_assignment)
      achievement = create(:dossier_achievement, assignment: assignment)
      assignment.update_columns(deleted_at: 31.days.ago)

      described_class.perform_now

      expect(Dossier::Assignment.exists?(assignment.id)).to be false
      expect(Dossier::Achievement.exists?(achievement.id)).to be false
      expect(Dossier::Engagement.exists?(assignment.engagement_id)).to be true
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves an Assignment deleted less than 30 days ago untouched" do
      assignment = create(:dossier_assignment)
      assignment.update_columns(deleted_at: 1.day.ago)
      described_class.perform_now
      expect(Dossier::Assignment.exists?(assignment.id)).to be true
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Leaves a kept Assignment untouched regardless of age" do
      assignment = create(:dossier_assignment, created_at: 1.year.ago)
      described_class.perform_now
      expect(Dossier::Assignment.exists?(assignment.id)).to be true
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Moves the purged Assignment's Training up to its Engagement" do
      assignment = create(:dossier_assignment)
      course = create(:dossier_credential, user: assignment.engagement.user, engagement: assignment.engagement,
                                           assignment: assignment)
      assignment.update_columns(deleted_at: 31.days.ago)

      described_class.perform_now

      expect(course.reload).to have_attributes(assignment_id: nil, engagement_id: assignment.engagement_id)
    end
  end
end
