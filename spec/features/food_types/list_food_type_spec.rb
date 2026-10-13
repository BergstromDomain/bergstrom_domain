# spec/features/food_types/list_food_type_spec.rb

require "rails_helper"

RSpec.describe "List Food Type", type: :feature do
  let!(:soup)  { create(:food_type, name: "Soup",  icon: "soup",  description: "Hot and cold soups.") }
  let!(:fish)  { create(:food_type, name: "Fish",  icon: "fish",  description: "Fish and seafood.") }
  let!(:bread) { create(:food_type, name: "Bread", icon: "wheat", description: "Loaves and buns.") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit food_types_path }

    it "Displays the page title" do
      expect(page).to have_selector("h1.page-title", text: "Food Types")
    end

    it "Displays food types in alphabetical order by name" do
      expect(page.text.index("Bread")).to be < page.text.index("Fish")
      expect(page.text.index("Fish")).to be < page.text.index("Soup")
    end

    it "Renders an SVG icon and a description for each food type" do
      expect(page).to have_selector("td[data-testid='food-type-icon'] svg", count: 3)
      expect(page).to have_selector("td[data-testid='food-type-description']", count: 3)
    end

    it "Links each food type name to its show page" do
      expect(page).to have_link("Soup", href: food_type_path(soup))
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Displays an empty state message when no food types exist" do
      FoodType.delete_all
      visit food_types_path
      expect(page).to have_selector("[data-testid='empty-state']")
      expect(page).not_to have_selector(".data-table")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Renders the same page for a signed-in 'Uno User'" do
      sign_in_as create(:user, :app_user)
      visit food_types_path
      expect(page).to have_selector("h1.page-title", text: "Food Types")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Sorts food types case-insensitively" do
      create(:food_type, name: "appetizers", icon: "salad")
      visit food_types_path
      expect(page.text.index("appetizers")).to be < page.text.index("Bread")
    end
  end
end
