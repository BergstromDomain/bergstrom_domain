# spec/db/cookbook_seeds_spec.rb

require "rails_helper"

RSpec.describe "db/seeds/cookbook.rb" do
  def load_seeds = load Rails.root.join("db/seeds/cookbook.rb")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates the starting Cuisines, Food Types and Languages, all valid" do
      load_seeds
      expect([ Cuisine.count, FoodType.count, Language.count ]).to eq([ 18, 14, 5 ])
      expect(Language.find_by!(code: "sv")).to have_attributes(name: "Swedish", flag: "🇸🇪")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Does not overwrite a row an admin has since edited" do
      create(:cuisine, name: "Swedish", flag: "🇸🇪", description: "Edited by hand")
      load_seeds
      expect(Cuisine.find_by!(name: "Swedish").description).to eq("Edited by hand")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Is safe to run twice" do
      load_seeds
      expect { load_seeds }.not_to change { [ Cuisine.count, FoodType.count, Language.count ] }
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Gives every Food Type a distinct, real Lucide icon" do
      load_seeds
      icons = FoodType.pluck(:icon)
      expect(icons.uniq.size).to eq(icons.size)
      expect(icons).to all(satisfy { |icon| FoodType::LUCIDE_VALID_ICONS.include?(icon) })
    end
  end
end
