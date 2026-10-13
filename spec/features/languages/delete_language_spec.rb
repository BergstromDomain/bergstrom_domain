# spec/features/languages/delete_language_spec.rb

require "rails_helper"

RSpec.describe "Delete Language", type: :feature do
  let(:admin)     { create(:user, :admin) }
  let!(:language) { create(:language, name: "Swedish", code: "sv") }

  before { sign_in_as(admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Deletes an unused language and redirects to the index with a toast" do
      visit language_path(language)
      expect { click_button "Delete Language" }.to change(Language, :count).by(-1)
      expect(page).to have_current_path(languages_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Swedish has been successfully deleted")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Does not delete a language that recipes use, and says why" do
      create(:recipe, language: language)
      visit language_path(language)
      expect { click_button "Delete Language" }.not_to change(Language, :count)
      expect(page).to have_content("Cannot delete record because dependent recipes exist")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Allows 'Sam SysAdmin' to delete a language" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit language_path(language)
      click_button "Delete Language"
      expect(page).to have_current_path(languages_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Does not show the 'Delete' button to 'Gary Guest'" do
      click_button "Sign Out"
      visit language_path(language)
      expect(page).not_to have_button("Delete Language")
    end
  end
end
