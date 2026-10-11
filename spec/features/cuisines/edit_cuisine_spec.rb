# spec/features/cuisines/edit_cuisine_spec.rb

require "rails_helper"

RSpec.describe "Edit Cuisine", type: :feature do
  let(:admin)    { create(:user, :admin) }
  let!(:cuisine) { create(:cuisine, name: "Swedish", flag: "🇸🇪", description: "Food from Sweden.") }

  before { sign_in_as(admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Pre-populates the form and previews the current flag" do
      visit edit_cuisine_path(cuisine)
      expect(page).to have_selector("h1.page-title", text: "Swedish")
      expect(page).to have_field("Name", with: "Swedish")
      expect(page).to have_field("Flag", with: "🇸🇪")
      expect(page).to have_selector("[data-testid='edit-panel-main'] .flag-badge__flag", text: "🇸🇪")
    end

    it "Updates the name, regenerates the slug and shows both toasts" do
      visit edit_cuisine_path(cuisine)
      fill_in "Name", with: "Scandinavian"
      click_button "Update Cuisine"

      expect(page).to have_current_path(cuisine_path("scandinavian"))
      expect(page).to have_css("[data-testid='flash-success']", text: "Scandinavian has been successfully updated")
      expect(page).to have_css("[data-testid='flash-info']", text: "Swedish has been updated to Scandinavian")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error when the flag is invalid" do
      visit edit_cuisine_path(cuisine)
      fill_in "Flag", with: "x"
      click_button "Update Cuisine"

      expect(page).to have_content("must be a single emoji")
      expect(cuisine.reload.flag).to eq("🇸🇪")
    end

    it "Redirects 'Charlie Content Creator' to the cuisines index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit edit_cuisine_path(cuisine)
      expect(page).to have_current_path(cuisines_path)
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      click_button "Sign Out"
      visit edit_cuisine_path(cuisine)
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Old slug resolves to the record after a name change" do
      visit edit_cuisine_path(cuisine)
      fill_in "Name", with: "Scandinavian"
      click_button "Update Cuisine"
      visit cuisine_path("swedish")
      expect(page).to have_selector("h1.page-title", text: "Scandinavian")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Preserves the description when only the flag is changed" do
      visit edit_cuisine_path(cuisine)
      fill_in "Flag", with: "🌍"
      click_button "Update Cuisine"
      expect(page).to have_selector("[data-testid='cuisine-description']", text: "Food from Sweden.")
    end
  end
end
