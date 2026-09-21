# spec/features/guide_pages/list_guide_page_spec.rb

require "rails_helper"

RSpec.describe "List Guide Page", type: :feature do
  let!(:core)          { create(:guide_page, title: "Getting Started", app_section: "core") }
  let!(:chronicle)     { create(:guide_page, title: "Chronicle Guide", app_section: "blog_posts") }
  let!(:occasions)     { create(:guide_page, title: "Occasions Guide", app_section: "event_tracker") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit guide_pages_path }

    it "Displays the page title" do
      expect(page).to have_selector("h1.page-title", text: "User Guide Pages")
    end

    it "Displays all guide pages" do
      expect(page).to have_content("Getting Started")
      expect(page).to have_content("Chronicle Guide")
      expect(page).to have_content("Occasions Guide")
    end

    it "Displays guide pages in alphabetical order by title" do
      main_text = find("[data-testid='main-content']").text
      expect(main_text.index("Chronicle Guide")).to be < main_text.index("Getting Started")
      expect(main_text.index("Getting Started")).to be < main_text.index("Occasions Guide")
    end

    it "Displays the app section for each guide page" do
      expect(page).to have_selector("td[data-testid='guide-page-app-section']", text: "Core")
      expect(page).to have_selector("td[data-testid='guide-page-app-section']", text: "Chronicle")
      expect(page).to have_selector("td[data-testid='guide-page-app-section']", text: "Occasions")
    end

    it "Links each guide page title to its show page" do
      expect(page).to have_link("Getting Started", href: guide_page_path(core))
      expect(page).to have_link("Chronicle Guide",  href: guide_page_path(chronicle))
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Displays an empty state message when no guide pages exist" do
      GuidePage.delete_all
      visit guide_pages_path
      expect(page).to have_http_status(:ok)
      expect(page).to have_selector("[data-testid='empty-state']")
      expect(page).not_to have_selector(".data-table")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Renders the same page regardless of authentication status" do
      sign_in_as create(:user, :app_user)
      visit guide_pages_path
      expect(page).to have_selector("h1.page-title", text: "User Guide Pages")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Sorts guide pages case-insensitively" do
      create(:guide_page, title: "admin overview", app_section: "admin")
      visit guide_pages_path
      main_text = find("[data-testid='main-content']").text
      expect(main_text.index("admin overview")).to be < main_text.index("Chronicle Guide")
    end
  end
end
