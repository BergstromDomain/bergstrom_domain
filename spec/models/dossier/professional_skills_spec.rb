# spec/models/dossier/professional_skills_spec.rb
require "rails_helper"

# Professional (soft) Skills: a Skill Category marked soft keeps its Skills,
# and its sub-categories' Skills, out of years of experience and the CV's
# skills table; an Achievement can say the situation it came from.
RSpec.describe "Dossier Professional Skills", type: :model do
  let(:user) { create(:user, :content_creator) }
  let(:soft) { create(:dossier_skill_category, name: "Professional Skills", soft: true) }
  let!(:leadership) { create(:dossier_skill, name: "Leadership", skill_category: soft) }
  let!(:jira) { create(:dossier_skill, name: "Jira") }
  let(:assignment) do
    create(:dossier_assignment, engagement: create(:dossier_engagement, user: user, start_month: "2020-01", end_month: "2021-12"),
                                start_month: "2020-01", end_month: "2021-12")
  end

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { expect(Dossier::SkillCategory.new).to have_db_column(:soft).of_type(:boolean).with_options(null: false, default: false) }
    it { expect(Dossier::Achievement.new).to have_db_column(:situation).of_type(:text) }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Knows a soft Skill from a technical one" do
      expect(leadership).to be_soft
      expect(jira).not_to be_soft
    end

    it "Splits a user's Skills into technical ones and professional ones" do
      create(:dossier_achievement, assignment: assignment, skills_text: "Leadership, Jira")
      calculator = Dossier::ExperienceCalculator.new(user, today: Date.new(2026, 11, 11))

      expect(calculator.technical_skills.map(&:skill)).to eq([ jira ])
      expect(calculator.professional_skills.map(&:skill)).to eq([ leadership ])
      expect(calculator.professional_skills.first.achievements.size).to eq(1)
    end

    it "Keeps an Achievement's situation, tidied" do
      achievement = create(:dossier_achievement, assignment: assignment, situation: "  Two vendors blamed each other for outages.  ")

      expect(achievement.situation).to eq("Two vendors blamed each other for outages.")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves a category technical unless it's marked soft" do
      expect(Dossier::SkillCategory.create!(name: "Testing Things")).not_to be_soft
    end

    it "Blanks an empty situation" do
      expect(create(:dossier_achievement, assignment: assignment, situation: " ").situation).to be_nil
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Makes a soft category's sub-category soft too" do
      coaching = create(:dossier_skill_category, name: "Coaching", parent: soft)

      expect(create(:dossier_skill, name: "Mentoring", skill_category: coaching)).to be_soft
    end

    it "Links a Professional Skill typed by its alias" do
      adaptability = create(:dossier_skill, name: "Adaptability", skill_category: soft, aliases: [ "Flexibility and Adaptability" ])
      achievement = create(:dossier_achievement, assignment: assignment, skills_text: "flexibility and adaptability")

      expect(achievement.skills).to eq([ adaptability ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Counts a Skill's years again once it's moved to a technical category" do
      create(:dossier_achievement, assignment: assignment, skills_text: "Leadership")
      leadership.update!(skill_category: create(:dossier_skill_category, name: "Methods"))
      calculator = Dossier::ExperienceCalculator.new(user, today: Date.new(2026, 11, 11))

      expect(calculator.technical_skills.map(&:skill)).to eq([ leadership ])
      expect(calculator.professional_skills).to be_empty
    end
  end
end
