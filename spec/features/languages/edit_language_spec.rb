# spec/features/languages/edit_language_spec.rb

require "rails_helper"

RSpec.describe "Edit Language", type: :feature do
  let(:admin)     { create(:user, :admin) }
  let!(:language) { create(:language, name: "Swedish", code: "sv", flag: "🇸🇪") }

  before { sign_in_as(admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Pre-populates the form and previews the current flag" do
      visit edit_language_path(language)
      expect(page).to have_field("Name", with: "Swedish")
      expect(page).to have_field("Code", with: "sv")
      expect(page).to have_selector("[data-testid='edit-panel-main'] .flag-badge__flag", text: "🇸🇪")
    end

    it "Updates the name and shows both toasts" do
      visit edit_language_path(language)
      fill_in "Name", with: "Svenska"
      click_button "Update Language"

      expect(page).to have_css("[data-testid='flash-success']", text: "Svenska has been successfully updated")
      expect(page).to have_css("[data-testid='flash-info']", text: "Swedish has been updated to Svenska")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error when the code is blank" do
      visit edit_language_path(language)
      fill_in "Code", with: ""
      click_button "Update Language"

      expect(page).to have_selector("[data-testid='field-error']", text: "can't be blank")
      expect(language.reload.code).to eq("sv")
    end

    it "Redirects 'Charlie Content Creator' to the languages index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit edit_language_path(language)
      expect(page).to have_current_path(languages_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Old slug resolves to the record after a name change" do
      visit edit_language_path(language)
      fill_in "Name", with: "Svenska"
      click_button "Update Language"
      visit language_path("swedish")
      expect(page).to have_selector("h1.page-title", text: "Svenska")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Preserves the flag when only the code is changed" do
      visit edit_language_path(language)
      fill_in "Code", with: "SE"
      click_button "Update Language"
      expect(language.reload).to have_attributes(code: "se", flag: "🇸🇪")
    end
  end
end
