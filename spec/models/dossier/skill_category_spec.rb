# spec/models/dossier/skill_category_spec.rb
require "rails_helper"

RSpec.describe Dossier::SkillCategory, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to have_many(:skills).dependent(:restrict_with_error) }

    it "Can't be deleted while a Skill uses it" do
      category = create(:dossier_skill_category)
      create(:dossier_skill, skill_category: category)
      expect(category.destroy).to be(false)
    end
  end

  it "Uses the dossier_ table prefix" do
    expect(described_class.table_name).to eq("dossier_skill_categories")
  end

  it_behaves_like "Dossier named reference data", :dossier_skill_category
end
