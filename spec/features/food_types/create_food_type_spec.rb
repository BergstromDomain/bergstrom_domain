# spec/features/food_types/create_food_type_spec.rb

require "rails_helper"

RSpec.describe "Create Food Type", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in_as(admin) }

  def fill_food_type(name: "Soup", icon: "soup", description: "Hot and cold soups.")
    fill_in "Name",        with: name
    fill_in "Icon",        with: icon
    fill_in "Description", with: description
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates a food type and shows it with a toast" do
      visit new_food_type_path
      fill_food_type
      click_button "Create Food Type"

      expect(page).to have_selector("h1.page-title", text: "Soup")
      expect(page).to have_css("[data-testid='flash-success']", text: "Soup has been successfully created")
      expect(FoodType.find_by!(name: "Soup").icon).to eq("soup")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error when the icon is not a valid Lucide icon name" do
      visit new_food_type_path
      fill_food_type(icon: "not-a-real-icon")
      click_button "Create Food Type"

      expect(page).to have_content("is not a valid Lucide icon name")
      expect(FoodType.count).to eq(0)
    end

    it "Shows an error when the icon is already used by another food type" do
      create(:food_type, name: "Broth", icon: "soup")
      visit new_food_type_path
      fill_food_type
      click_button "Create Food Type"

      expect(page).to have_content("has already been taken")
      expect(FoodType.count).to eq(1)
    end

    it "Shows an error when the name is missing" do
      visit new_food_type_path
      fill_food_type(name: "")
      click_button "Create Food Type"

      expect(page).to have_selector("[data-testid='field-error']", text: "can't be blank")
    end

    it "Redirects 'Charlie Content Creator' to the food types index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit new_food_type_path
      expect(page).to have_current_path(food_types_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Re-renders the form with entered values when validation fails" do
      visit new_food_type_path
      fill_food_type(icon: "not-a-real-icon")
      click_button "Create Food Type"

      expect(page).to have_field("Name", with: "Soup")
      expect(page).to have_field("Icon", with: "not-a-real-icon")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      click_button "Sign Out"
      visit new_food_type_path
      expect(page).to have_current_path(new_session_path)
    end
  end
end
