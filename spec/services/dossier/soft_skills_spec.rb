# spec/services/dossier/soft_skills_spec.rb
require "rails_helper"

# Dossier::SoftSkills seeds the "Soft Skills" category and
# its Skills; soft Skills stay off the CV's skills table and a CV Variant's
# Skill choices, and an Achievement's situation never reaches a CV.
RSpec.describe Dossier::SoftSkills do
  let(:user) { create(:user, :content_creator) }
  let(:today) { Date.new(2026, 11, 11) }

  before { create(:dossier_skill, name: "Jira", skill_category: create(:dossier_skill_category, name: "Test Tools")) }

  def achievement(**attributes)
    engagement = create(:dossier_engagement, user: user, start_month: "2020-01", end_month: "2021-12")
    assignment = create(:dossier_assignment, engagement: engagement, start_month: "2020-01", end_month: "2021-12")
    create(:dossier_achievement, assignment: assignment, **attributes)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Seeds a soft category with nine Skills, the ad's wording as aliases" do
      described_class.seed!
      category = Dossier::SkillCategory.find_by!(name: "Soft Skills")

      expect(category).to be_soft
      expect(category.skills.pluck(:name)).to match_array(described_class::SKILLS.keys)
      expect(Dossier::Skill.find_by_name_or_alias("Flexibility and Adaptability").name).to eq("Adaptability")
      expect(Dossier::Skill.find_by_name_or_alias("Cross-Functional Support").name).to eq("Cross-Functional Collaboration")
    end

    it "Keeps soft Skills and situations off the CV, which still lists the technical Skills and the Achievement" do
      described_class.seed!
      create(:dossier_profile, user: user, display_name: "Alex Example")
      achievement(text: "Ran daily defect triage", skills_text: "Leadership, Jira", situation: "Defects sat unowned for weeks")
      cv = Dossier::CvDocument.new(user, today: today)

      expect(cv.skills.flat_map { |_, line| line }.join).to include("Jira")
      expect(cv.skills.flat_map { |heading, line| [ heading, line ] }.join).not_to include("Leadership")
      expect(cv.skills.map(&:first)).not_to include("Soft Skills")
      expect(cv.experience.first.assignments.first.achievements).to eq([ "Ran daily defect triage" ])
      docx = docx_parts(Dossier::CvDocx.new(cv).render).values.join
      expect(docx).not_to include("Defects sat unowned")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves soft Skills out of a CV Variant's Skills" do
      described_class.seed!
      achievement(skills_text: "Leadership, Jira")
      variant = create(:dossier_cv_variant, user: user)
      selection = Dossier::CvSelection.new(variant, today: today)

      expect(selection.included?(Dossier::Skill.find_by!(name: "Jira"))).to be(true)
      expect(selection.included?(Dossier::Skill.find_by!(name: "Leadership"))).to be(false)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Uses a Soft Skills category that's already there, marking it soft" do
      existing = create(:dossier_skill_category, name: "soft skills")
      described_class.seed!

      expect(existing.reload).to be_soft
      expect(Dossier::SkillCategory.where("LOWER(name) = 'soft skills'").count).to eq(1)
    end

    it "Renames the earlier Professional Skills category to Soft Skills, keeping its Skills" do
      earlier = create(:dossier_skill_category, name: "Professional Skills", soft: true)
      leadership = create(:dossier_skill, name: "Leadership", skill_category: earlier)
      described_class.seed!

      expect(earlier.reload.name).to eq("Soft Skills")
      expect(leadership.reload.skill_category).to eq(earlier)
      expect(Dossier::SkillCategory.where(name: [ "Soft Skills", "Professional Skills" ]).count).to eq(1)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Changes nothing when run again, keeping edits made since" do
      described_class.seed!
      Dossier::Skill.find_by!(name: "Leadership").update!(description: "My own words")

      expect { described_class.seed! }.not_to change(Dossier::Skill, :count)
      expect(Dossier::Skill.find_by!(name: "Leadership").description).to eq("My own words")
    end

    it "Leaves a same-named Skill where it is, in its own category" do
      methods = create(:dossier_skill_category, name: "Methods & Processes")
      create(:dossier_skill, name: "Stakeholder Management", skill_category: methods)
      described_class.seed!

      expect(Dossier::Skill.where(name: "Stakeholder Management").sole.skill_category).to eq(methods)
    end
  end
end
