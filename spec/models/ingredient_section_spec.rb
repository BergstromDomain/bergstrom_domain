# spec/models/ingredient_section_spec.rb
require "rails_helper"

RSpec.describe IngredientSection, type: :model do
  subject { build(:ingredient_section) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:recipe_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:heading).of_type(:string) }
    it { is_expected.to have_db_column(:position).of_type(:integer).with_options(null: false) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:recipe) }
    it { is_expected.to have_many(:ingredients).dependent(:destroy) }
    it { is_expected.to accept_nested_attributes_for(:ingredients).allow_destroy(true) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "Validations" do
    # 1) Happy Path ──────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid with a heading" do
        expect(subject).to be_valid
      end
    end

    # 2) Negative Path ───────────────────────────────────────────────────────
    describe "Negative Path" do
      it "is invalid without a recipe" do
        subject.recipe = nil
        expect(subject).not_to be_valid
      end
    end

    # 3) Alternative Paths ───────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "is valid without a heading — a simple recipe's single list" do
        subject.heading = nil
        expect(subject).to be_valid
      end
    end

    # 4) Edge Cases ──────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "returns its ingredients in position order" do
        section = create(:ingredient_section)
        second = create(:ingredient, ingredient_section: section, position: 1, name: "second")
        first  = create(:ingredient, ingredient_section: section, position: 0, name: "first")
        expect(section.reload.ingredients).to eq([ first, second ])
      end
    end
  end
end
