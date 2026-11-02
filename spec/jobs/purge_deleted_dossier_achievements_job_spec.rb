# spec/jobs/purge_deleted_dossier_achievements_job_spec.rb
require "rails_helper"

RSpec.describe PurgeDeletedDossierAchievementsJob, type: :job do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Permanently destroys an Achievement deleted more than 30 days ago, with its Skill tags" do
      achievement = create(:dossier_achievement, skills_text: "Jira")
      achievement.update_columns(deleted_at: 31.days.ago)
      expect { described_class.perform_now }.to change(Dossier::AchievementSkill, :count).by(-1)
      expect(Dossier::Achievement.exists?(achievement.id)).to be false
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves an Achievement deleted less than 30 days ago untouched" do
      achievement = create(:dossier_achievement)
      achievement.update_columns(deleted_at: 1.day.ago)
      described_class.perform_now
      expect(Dossier::Achievement.exists?(achievement.id)).to be true
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Leaves a kept Achievement untouched regardless of age" do
      achievement = create(:dossier_achievement, created_at: 1.year.ago)
      described_class.perform_now
      expect(Dossier::Achievement.exists?(achievement.id)).to be true
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves the tagged Skill itself in place" do
      achievement = create(:dossier_achievement, skills_text: "Jira")
      achievement.update_columns(deleted_at: 31.days.ago)
      described_class.perform_now
      expect(Dossier::Skill.where(name: "Jira")).to exist
    end
  end
end
