# spec/features/food_types/edit_food_type_spec.rb

require "rails_helper"

RSpec.describe "Edit Food Type", type: :feature do
  let(:admin)      { create(:user, :admin) }
  let!(:food_type) { create(:food_type, name: "Soup", icon: "soup", description: "Hot and cold soups.") }

  before { sign_in_as(admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Pre-populates the form and previews the current icon" do
      visit edit_food_type_path(food_type)
      expect(page).to have_field("Name", with: "Soup")
      expect(page).to have_field("Icon", with: "soup")
      expect(page).to have_selector("[data-testid='edit-panel-main'] svg")
    end

    it "Updates the icon and shows a toast" do
      visit edit_food_type_path(food_type)
      fill_in "Icon", with: "cooking-pot"
      click_button "Update Food Type"

      expect(page).to have_css("[data-testid='flash-success']", text: "Soup has been successfully updated")
      expect(food_type.reload.icon).to eq("cooking-pot")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error when the icon is invalid" do
      visit edit_food_type_path(food_type)
      fill_in "Icon", with: "not-a-real-icon"
      click_button "Update Food Type"

      expect(page).to have_content("is not a valid Lucide icon name")
      expect(food_type.reload.icon).to eq("soup")
    end

    it "Redirects 'Charlie Content Creator' to the food types index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit edit_food_type_path(food_type)
      expect(page).to have_current_path(food_types_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Old slug resolves to the record after a name change" do
      visit edit_food_type_path(food_type)
      fill_in "Name", with: "Soups"
      click_button "Update Food Type"
      visit food_type_path("soup")
      expect(page).to have_selector("h1.page-title", text: "Soups")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows an error when the icon has surrounding whitespace" do
      visit edit_food_type_path(food_type)
      fill_in "Icon", with: " soup "
      click_button "Update Food Type"
      expect(page).to have_content("is not a valid Lucide icon name")
    end
  end
end
