# spec/features/languages/list_language_spec.rb

require "rails_helper"

RSpec.describe "List Language", type: :feature do
  let!(:swedish) { create(:language, name: "Swedish", code: "sv", flag: "🇸🇪") }
  let!(:english) { create(:language, name: "English", code: "en", flag: "🇬🇧") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit languages_path }

    it "Displays the page title" do
      expect(page).to have_selector("h1.page-title", text: "Languages")
    end

    it "Displays languages in alphabetical order with their codes" do
      expect(page.text.index("English")).to be < page.text.index("Swedish")
      expect(page).to have_selector("td[data-testid='language-code']", text: "sv")
    end

    it "Shows each language's flag with the Language badge" do
      within(all("[data-testid='language-row']").first) do
        expect(page).to have_selector("[data-testid='language-flag'] .flag-badge__flag", text: "🇬🇧")
        expect(page).to have_selector("[data-testid='language-flag'] .flag-badge__icon svg")
      end
    end

    it "Links each language name to its show page" do
      expect(page).to have_link("Swedish", href: language_path(swedish))
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Displays an empty state message when no languages exist" do
      Language.delete_all
      visit languages_path
      expect(page).to have_selector("[data-testid='empty-state']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Renders the same page for a signed-in 'Uno User'" do
      sign_in_as create(:user, :app_user)
      visit languages_path
      expect(page).to have_selector("h1.page-title", text: "Languages")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Sorts languages case-insensitively" do
      create(:language, name: "dutch", code: "nl", flag: "🇳🇱")
      visit languages_path
      expect(page.text.index("dutch")).to be < page.text.index("English")
    end
  end
end
