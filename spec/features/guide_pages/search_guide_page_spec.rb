# spec/features/guide_pages/search_guide_page_spec.rb

require "rails_helper"

RSpec.describe "Search Guide Page", type: :feature do
  let!(:getting_started) do
    create(:guide_page, title: "Getting Started", app_section: "core", body: "Welcome to the app.")
  end
  let!(:sign_up) do
    create(:guide_page, title: "Sign Up", app_section: "core", body: "How to create an account.")
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows only guide pages matching the query in the title" do
      visit guide_pages_path
      fill_in "Search the User Guide", with: "Getting"
      click_button "Search"

      within("[data-testid='guide-page-table']") do
        expect(page).to have_content("Getting Started")
        expect(page).not_to have_content("Sign Up")
      end
    end

    it "Shows only guide pages matching the query in the body" do
      visit guide_pages_path
      fill_in "Search the User Guide", with: "account"
      click_button "Search"

      within("[data-testid='guide-page-table']") do
        expect(page).to have_content("Sign Up")
        expect(page).not_to have_content("Getting Started")
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an empty state naming the query when nothing matches" do
      visit guide_pages_path
      fill_in "Search the User Guide", with: "nonexistent term"
      click_button "Search"

      expect(page).to have_selector("[data-testid='empty-state']", text: "nonexistent term")
      expect(page).not_to have_selector(".data-table")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows all guide pages again after clearing the search" do
      visit guide_pages_path(q: "Getting")
      within("[data-testid='guide-page-table']") { expect(page).not_to have_content("Sign Up") }

      click_link "Clear"

      within("[data-testid='guide-page-table']") do
        expect(page).to have_content("Getting Started")
        expect(page).to have_content("Sign Up")
      end
    end

    it "Is usable by 'Gary Guest' without signing in" do
      visit guide_pages_path
      fill_in "Search the User Guide", with: "Getting"
      click_button "Search"

      expect(page).to have_content("Getting Started")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Is case-insensitive" do
      visit guide_pages_path
      fill_in "Search the User Guide", with: "GETTING"
      click_button "Search"

      expect(page).to have_content("Getting Started")
    end

    it "Preserves the search field's value after submitting" do
      visit guide_pages_path
      fill_in "Search the User Guide", with: "Getting"
      click_button "Search"

      expect(page).to have_field("Search the User Guide", with: "Getting")
    end
  end
end
