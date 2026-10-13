# spec/features/food_types/delete_food_type_spec.rb

require "rails_helper"

RSpec.describe "Delete Food Type", type: :feature do
  let(:admin)      { create(:user, :admin) }
  let!(:food_type) { create(:food_type, name: "Soup", icon: "soup") }

  before { sign_in_as(admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Deletes an unused food type and redirects to the index with a toast" do
      visit food_type_path(food_type)
      expect { click_button "Delete Food Type" }.to change(FoodType, :count).by(-1)
      expect(page).to have_current_path(food_types_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Soup has been successfully deleted")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Does not delete a food type that recipes use, and says why" do
      create(:recipe, food_types: [ food_type ])
      visit food_type_path(food_type)
      expect { click_button "Delete Food Type" }.not_to change(FoodType, :count)
      expect(page).to have_content("Cannot delete record because dependent recipes exist")
    end

    it "Does not delete one that a recipe uses only as its second choice" do
      create(:recipe, food_types: [ create(:food_type), food_type ])
      visit food_type_path(food_type)
      expect { click_button "Delete Food Type" }.not_to change(FoodType, :count)
      expect(page).to have_content("Cannot delete record because dependent recipes exist")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Allows 'Sam SysAdmin' to delete a food type" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit food_type_path(food_type)
      click_button "Delete Food Type"
      expect(page).to have_current_path(food_types_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Does not show the 'Delete' button to 'Gary Guest'" do
      click_button "Sign Out"
      visit food_type_path(food_type)
      expect(page).not_to have_button("Delete Food Type")
    end
  end
end
