# spec/jobs/purge_deleted_dossier_engagements_job_spec.rb
require "rails_helper"

RSpec.describe PurgeDeletedDossierEngagementsJob, type: :job do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Permanently destroys an Engagement deleted more than 30 days ago, with its Assignments and Achievements" do
      assignment = create(:dossier_assignment, test_tools_na: false, test_tools_text: "Jira")
      achievement = create(:dossier_achievement, assignment: assignment, skills_text: "Jira")
      assignment.engagement.update_columns(deleted_at: 31.days.ago)

      described_class.perform_now

      expect(Dossier::Engagement.exists?(assignment.engagement_id)).to be false
      expect(Dossier::Assignment.exists?(assignment.id)).to be false
      expect(Dossier::Achievement.exists?(achievement.id)).to be false
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves an Engagement deleted less than 30 days ago untouched" do
      engagement = create(:dossier_engagement)
      engagement.update_columns(deleted_at: 1.day.ago)
      described_class.perform_now
      expect(Dossier::Engagement.exists?(engagement.id)).to be true
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Leaves a kept Engagement untouched regardless of age" do
      engagement = create(:dossier_engagement, created_at: 1.year.ago)
      described_class.perform_now
      expect(Dossier::Engagement.exists?(engagement.id)).to be true
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves the Skills and Organisations it used in place" do
      assignment = create(:dossier_assignment, test_tools_na: false, test_tools_text: "Jira")
      assignment.engagement.update_columns(deleted_at: 31.days.ago)
      described_class.perform_now
      expect(Dossier::Skill.where(name: "Jira")).to exist
      expect(Dossier::Organisation.exists?(assignment.client_id)).to be true
    end
  end
end
