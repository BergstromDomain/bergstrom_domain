# spec/features/languages/show_language_spec.rb

require "rails_helper"

RSpec.describe "Show Language", type: :feature do
  let!(:language) { create(:language, name: "Swedish", code: "sv", flag: "🇸🇪") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit language_path(language) }

    it "Displays the name, flag and code" do
      expect(page).to have_selector("h1.page-title", text: "Swedish")
      expect(page).to have_selector("[data-testid='show-panel-main'] .flag-badge--large .flag-badge__flag", text: "🇸🇪")
      expect(page).to have_selector("[data-testid='language-code-value']", text: "sv")
      expect(page).to have_selector("[data-testid='language-name-value']", text: "Swedish")
    end

    it "Shows a back link to the index" do
      expect(page).to have_link("Back", href: languages_path, exact: true)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Gary Guest'" do
      expect(page).not_to have_link("Edit Language")
      expect(page).not_to have_button("Delete Language")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Returns 404 for a non-existent slug" do
      visit language_path("non-existent-slug")
      expect(page).to have_http_status(:not_found)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Charlie Content Creator'" do
      sign_in_as create(:user, :content_creator)
      visit language_path(language)
      expect(page).not_to have_link("Edit Language")
      expect(page).not_to have_button("Delete Language")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows the 'Edit' and the 'Delete' buttons to 'Adam Admin'" do
      sign_in_as create(:user, :admin)
      visit language_path(language)
      expect(page).to have_link("Edit Language", href: edit_language_path(language))
      expect(page).to have_button("Delete Language")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Is accessible by slug" do
      visit language_path("swedish")
      expect(page).to have_selector("h1.page-title", text: "Swedish")
    end
  end
end
