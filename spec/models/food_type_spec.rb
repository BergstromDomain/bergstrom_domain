# spec/models/food_type_spec.rb
require "rails_helper"

RSpec.describe FoodType, type: :model do
  subject { build(:food_type) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:icon).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to have_many(:recipe_food_types) }
    it { is_expected.to have_many(:recipes).through(:recipe_food_types).dependent(:restrict_with_error) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "Validations" do
    # 1) Happy Path ───────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid with all required fields" do
        expect(build(:food_type, name: "Dessert", icon: "cake-slice")).to be_valid
      end
    end

    # 2) Negative Path ────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "is invalid when name is blank" do
        food_type = build(:food_type, name: "")
        expect(food_type).not_to be_valid
        expect(food_type.errors[:name]).to include("can't be blank")
      end

      it "is invalid when name is a duplicate (different case)" do
        create(:food_type, name: "Dessert", icon: "cake-slice")
        food_type = build(:food_type, name: "dessert", icon: "cookie")
        expect(food_type).not_to be_valid
        expect(food_type.errors[:name]).to include("has already been taken")
      end

      it "is invalid when description is blank" do
        food_type = build(:food_type, description: "")
        expect(food_type).not_to be_valid
        expect(food_type.errors[:description]).to include("can't be blank")
      end

      it "is invalid when icon is blank" do
        food_type = build(:food_type, icon: "")
        expect(food_type).not_to be_valid
        expect(food_type.errors[:icon]).to include("can't be blank")
      end

      it "is invalid when icon is already taken by another record" do
        create(:food_type, name: "Dessert", icon: "cake-slice")
        food_type = build(:food_type, name: "Cake", icon: "cake-slice")
        expect(food_type).not_to be_valid
        expect(food_type.errors[:icon]).to include("has already been taken")
      end

      it "is invalid when icon name is not in the Lucide icon set" do
        food_type = build(:food_type, icon: "not-a-real-icon")
        expect(food_type).not_to be_valid
        expect(food_type.errors[:icon]).to include("is not a valid Lucide icon name")
      end
    end

    # 3) Alternative Paths ─────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "is valid when updating description without changing name" do
        food_type = create(:food_type, name: "Dessert", icon: "cake-slice")
        food_type.description = "Sweet things"
        expect(food_type).to be_valid
      end
    end

    # 4) Edge Cases ────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "regenerates its slug when renamed" do
        food_type = create(:food_type, name: "Dessert", icon: "cake-slice")
        food_type.update!(name: "Desserts")
        expect(food_type.slug).to eq("desserts")
      end

      it "uses its name as the toast label" do
        expect(build(:food_type, name: "Dessert").to_toast_label).to eq("Dessert")
      end
    end
  end
end
