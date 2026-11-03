# spec/models/dossier/skill_spec.rb
require "rails_helper"

RSpec.describe Dossier::Skill, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:skill_category_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:aliases).of_type(:string).with_options(array: true, null: false, default: []) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:skill_category) }
  end

  it_behaves_like "Dossier named reference data", :dossier_skill

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Takes aliases as comma-separated text" do
      skill = create(:dossier_skill, name: "Selenium", aliases_text: "Selenium WebDriver, WebDriver")
      expect(skill.aliases).to eq([ "Selenium WebDriver", "WebDriver" ])
      expect(skill.aliases_text).to eq("Selenium WebDriver, WebDriver")
    end

    it "Is found by name or alias, ignoring case" do
      skill = create(:dossier_skill, name: "Selenium", aliases_text: "Selenium WebDriver")
      expect(described_class.find_by_name_or_alias("selenium webdriver")).to eq(skill)
      expect(described_class.find_by_name_or_alias("SELENIUM")).to eq(skill)
    end

    it "Merges into another Skill: links move, its names become aliases, it's deleted" do
      ec = create(:dossier_skill, name: "Energy Components", aliases_text: "EC")
      old = create(:dossier_skill, name: "Energy Component", aliases_text: "EC Upgrade")
      assignment = create(:dossier_assignment, other_tools_na: false, other_tools_text: "Energy Component")
      achievement = create(:dossier_achievement, skills_text: "Energy Component")

      old.merge_into!(ec)

      expect(described_class.exists?(old.id)).to be(false)
      expect(ec.reload.aliases).to eq([ "EC", "Energy Component", "EC Upgrade" ])
      expect(assignment.reload.other_tools_text).to eq("Energy Components")
      expect(achievement.reload.skills_text).to eq("Energy Components")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid without a Skill Category" do
      skill = build(:dossier_skill, skill_category: nil)
      expect(skill).not_to be_valid
      expect(skill.errors[:skill_category]).to include("must exist")
    end

    it "Is invalid when an alias is another Skill's name" do
      create(:dossier_skill, name: "WebDriver")
      skill = build(:dossier_skill, name: "Selenium", aliases_text: "webdriver")
      expect(skill).not_to be_valid
      expect(skill.errors[:aliases]).to include("webdriver is already a Skill")
    end

    it "Is invalid when its name is another Skill's alias" do
      create(:dossier_skill, name: "Selenium", aliases_text: "WebDriver")
      skill = build(:dossier_skill, name: "webdriver")
      expect(skill).not_to be_valid
      expect(skill.errors[:name]).to include("is already an alias of Selenium")
    end

    it "Won't merge into itself" do
      skill = create(:dossier_skill)
      expect { skill.merge_into!(skill) }.to raise_error(ArgumentError, "A Skill can't be merged into itself")
      expect(described_class.exists?(skill.id)).to be(true)
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Is valid with no aliases" do
      expect(build(:dossier_skill, aliases_text: "")).to be_valid
    end

    it "Keeps its description when the kept Skill has none" do
      kept = create(:dossier_skill, description: nil)
      create(:dossier_skill, description: "A test tool.").merge_into!(kept)
      expect(kept.reload.description).to eq("A test tool.")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Drops blank, duplicate and own-name aliases" do
      skill = create(:dossier_skill, name: "Jira", aliases_text: " , JIRA Software, jira software, Jira,")
      expect(skill.aliases).to eq([ "JIRA Software" ])
    end

    it "Drops a link the kept Skill already has when merging, keeping the other lists' links" do
      kept = create(:dossier_skill, name: "Excel")
      old = create(:dossier_skill, name: "MS Excel")
      assignment = create(:dossier_assignment, test_tools_na: false, test_tools_text: "Excel, MS Excel",
                                               other_tools_na: false, other_tools_text: "MS Excel")
      create(:dossier_achievement, assignment: assignment, skills_text: "Excel, MS Excel")

      old.merge_into!(kept)

      expect(assignment.reload.test_tools_text).to eq("Excel")
      expect(assignment.other_tools_text).to eq("Excel")
      expect(Dossier::AchievementSkill.where(skill: kept).count).to eq(1)
    end

    it "Returns nil for a blank lookup" do
      expect(described_class.find_by_name_or_alias(" ")).to be_nil
    end
  end
end
