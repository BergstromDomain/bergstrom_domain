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
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Is valid with no aliases" do
      expect(build(:dossier_skill, aliases_text: "")).to be_valid
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Drops blank, duplicate and own-name aliases" do
      skill = create(:dossier_skill, name: "Jira", aliases_text: " , JIRA Software, jira software, Jira,")
      expect(skill.aliases).to eq([ "JIRA Software" ])
    end

    it "Returns nil for a blank lookup" do
      expect(described_class.find_by_name_or_alias(" ")).to be_nil
    end
  end
end
