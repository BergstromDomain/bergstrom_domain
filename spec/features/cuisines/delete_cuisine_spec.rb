# spec/features/cuisines/delete_cuisine_spec.rb

require "rails_helper"

RSpec.describe "Delete Cuisine", type: :feature do
  let(:admin)    { create(:user, :admin) }
  let!(:cuisine) { create(:cuisine, name: "Swedish") }

  before { sign_in_as(admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Deletes an unused cuisine and redirects to the index with a toast" do
      visit cuisine_path(cuisine)
      expect { click_button "Delete Cuisine" }.to change(Cuisine, :count).by(-1)
      expect(page).to have_current_path(cuisines_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Swedish has been successfully deleted")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Does not delete a cuisine that recipes use, and says why" do
      create(:recipe, cuisine: cuisine)
      visit cuisine_path(cuisine)
      expect { click_button "Delete Cuisine" }.not_to change(Cuisine, :count)
      expect(page).to have_current_path(cuisine_path(cuisine))
      expect(page).to have_content("Cannot delete record because dependent recipes exist")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Allows 'Sam SysAdmin' to delete a cuisine" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit cuisine_path(cuisine)
      click_button "Delete Cuisine"
      expect(page).to have_current_path(cuisines_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Lets a 'Charlie Content Creator' with a Cookbook delete override delete a cuisine" do
      creator = create(:user, :content_creator)
      create(:app_permission, user: creator, app_name: "recipes", can_delete: true)
      click_button "Sign Out"
      sign_in_as creator
      visit cuisine_path(cuisine)
      expect { click_button "Delete Cuisine" }.to change(Cuisine, :count).by(-1)
    end
  end
end
