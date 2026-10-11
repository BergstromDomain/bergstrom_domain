# spec/models/cuisine_spec.rb
require "rails_helper"

RSpec.describe Cuisine, type: :model do
  subject { build(:cuisine) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:flag).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to have_many(:recipes).dependent(:restrict_with_error) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "Validations" do
    # 1) Happy Path ───────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid with all required fields" do
        expect(build(:cuisine, name: "Swedish", flag: "🇸🇪")).to be_valid
      end
    end

    # 2) Negative Path ────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "is invalid when name is blank" do
        cuisine = build(:cuisine, name: "")
        expect(cuisine).not_to be_valid
        expect(cuisine.errors[:name]).to include("can't be blank")
      end

      it "is invalid when name is a duplicate (different case)" do
        create(:cuisine, name: "Swedish")
        cuisine = build(:cuisine, name: "swedish")
        expect(cuisine).not_to be_valid
        expect(cuisine.errors[:name]).to include("has already been taken")
      end

      it "is invalid when description is blank" do
        cuisine = build(:cuisine, description: "")
        expect(cuisine).not_to be_valid
        expect(cuisine.errors[:description]).to include("can't be blank")
      end

      it "is invalid when flag is blank" do
        cuisine = build(:cuisine, flag: "")
        expect(cuisine).not_to be_valid
        expect(cuisine.errors[:flag]).to include("can't be blank")
      end

      it "is invalid when flag is plain text rather than an emoji" do
        cuisine = build(:cuisine, flag: "SE")
        expect(cuisine).not_to be_valid
        expect(cuisine.errors[:flag]).to include("must be a single emoji, e.g. 🇸🇪")
      end
    end

    # 3) Alternative Paths ─────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "accepts a non-flag emoji for a regional cuisine with no national flag" do
        expect(build(:cuisine, name: "Mediterranean", flag: "🌍")).to be_valid
      end

      it "allows two cuisines to share a flag" do
        create(:cuisine, name: "Swedish", flag: "🇸🇪")
        expect(build(:cuisine, name: "Swedish Baking", flag: "🇸🇪")).to be_valid
      end
    end

    # 4) Edge Cases ────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "rejects two emoji in one flag" do
        cuisine = build(:cuisine, flag: "🇸🇪🇬🇧")
        expect(cuisine).not_to be_valid
        expect(cuisine.errors[:flag]).to include("must be a single emoji, e.g. 🇸🇪")
      end

      it "regenerates its slug when renamed" do
        cuisine = create(:cuisine, name: "Swedish")
        cuisine.update!(name: "Scandinavian")
        expect(cuisine.slug).to eq("scandinavian")
      end

      it "uses its name as the toast label" do
        expect(build(:cuisine, name: "Swedish").to_toast_label).to eq("Swedish")
      end
    end
  end
end
