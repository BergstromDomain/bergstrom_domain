# spec/features/food_types/show_food_type_spec.rb

require "rails_helper"

RSpec.describe "Show Food Type", type: :feature do
  let!(:food_type) { create(:food_type, name: "Soup", icon: "soup", description: "Hot and cold soups.") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit food_type_path(food_type) }

    it "Displays the name, icon and description" do
      expect(page).to have_selector("h1.page-title", text: "Soup")
      expect(page).to have_selector("[data-testid='show-panel-main'] [data-testid='food-type-icon'] svg")
      expect(page).to have_selector("[data-testid='food-type-description']", text: "Hot and cold soups.")
      expect(page).to have_selector("[data-testid='food-type-name-value']", text: "Soup")
    end

    it "Shows a back link to the index" do
      expect(page).to have_link("Back", href: food_types_path, exact: true)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Gary Guest'" do
      expect(page).not_to have_link("Edit Food Type")
      expect(page).not_to have_button("Delete Food Type")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Returns 404 for a non-existent slug" do
      visit food_type_path("non-existent-slug")
      expect(page).to have_http_status(:not_found)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Charlie Content Creator'" do
      sign_in_as create(:user, :content_creator)
      visit food_type_path(food_type)
      expect(page).not_to have_link("Edit Food Type")
      expect(page).not_to have_button("Delete Food Type")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows the 'Edit' and the 'Delete' buttons to 'Adam Admin'" do
      sign_in_as create(:user, :admin)
      visit food_type_path(food_type)
      expect(page).to have_link("Edit Food Type", href: edit_food_type_path(food_type))
      expect(page).to have_button("Delete Food Type")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Is accessible by slug" do
      visit food_type_path("soup")
      expect(page).to have_selector("h1.page-title", text: "Soup")
    end
  end
end
