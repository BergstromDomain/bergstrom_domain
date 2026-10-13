# spec/models/ingredient_spec.rb
require "rails_helper"

RSpec.describe Ingredient, type: :model do
  subject { build(:ingredient) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:ingredient_section_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:quantity).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:measurement).of_type(:string) }
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:comment).of_type(:text) }
    it { is_expected.to have_db_column(:position).of_type(:integer).with_options(null: false) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:ingredient_section) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "Validations" do
    # 1) Happy Path ──────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid with a quantity and a name" do
        expect(subject).to be_valid
      end
    end

    # 2) Negative Path ───────────────────────────────────────────────────────
    describe "Negative Path" do
      it { is_expected.to validate_presence_of(:quantity) }
      it { is_expected.to validate_presence_of(:name) }
    end

    # 3) Alternative Paths ───────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "is valid without a measurement or comment — e.g. '3 eggs'" do
        subject.measurement = nil
        subject.comment = nil
        expect(subject).to be_valid
      end
    end

    # 4) Edge Cases ──────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "accepts a free-text quantity like 'a pinch'" do
        subject.quantity = "a pinch"
        expect(subject).to be_valid
      end
    end
  end
end
