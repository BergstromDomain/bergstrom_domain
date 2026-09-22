require "rails_helper"

RSpec.describe "User Guide Redirect", type: :feature do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Redirects to the guide pages directory" do
      visit user_guide_path
      expect(page).to have_current_path(guide_pages_path)
      expect(page).to have_selector("h1.page-title", text: "User Guide Pages")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Still redirects to the directory when no guide pages exist yet" do
      visit user_guide_path
      expect(page).to have_current_path(guide_pages_path)
      expect(page).to have_selector("[data-testid='empty-state']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Is reachable by 'Gary Guest' without signing in" do
      visit user_guide_path
      expect(page).to have_http_status(:ok)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Redirects the same way regardless of how many guide pages exist" do
      create(:guide_page, title: "Getting Started", app_section: "core")
      create(:guide_page, title: "Sign Up", app_section: "core")
      visit user_guide_path
      expect(page).to have_current_path(guide_pages_path)
    end
  end
end
