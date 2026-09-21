require "rails_helper"

RSpec.describe "User Guide Redirect", type: :feature do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Redirects to the 'core' guide page when one exists" do
      core = create(:guide_page, title: "Getting Started", app_section: "core")
      visit user_guide_path
      expect(page).to have_current_path(guide_page_path(core))
      expect(page).to have_selector("h1.page-title", text: "Getting Started")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects to the guide pages directory when no 'core' page exists" do
      visit user_guide_path
      expect(page).to have_current_path(guide_pages_path)
      expect(page).to have_selector("h1.page-title", text: "User Guide Pages")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Is reachable by 'Gary Guest' without signing in" do
      create(:guide_page, title: "Getting Started", app_section: "core")
      visit user_guide_path
      expect(page).to have_http_status(:ok)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Falls back to the directory when other sections exist but 'core' does not" do
      create(:guide_page, title: "Occasions Guide", app_section: "event_tracker")
      visit user_guide_path
      expect(page).to have_current_path(guide_pages_path)
    end
  end
end
