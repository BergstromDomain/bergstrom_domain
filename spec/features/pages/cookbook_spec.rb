# spec/features/pages/cookbook_spec.rb
require "rails_helper"

RSpec.describe "Cookbook", type: :feature do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit cookbook_path }

    it "Shows the Cookbook heading and subtitle" do
      expect(page).to have_selector("h1.page-title", text: "Cookbook")
      expect(page).to have_selector(".page-header__subtitle", text: "Collect, cook, and share your favourite recipes.")
    end

    it "Renders via the shared app landing template with the Cookbook hero image" do
      expect(page).to have_selector("[data-testid='app-landing']")
      expect(page).to have_selector("img.app-landing__hero-image[alt='Cookbook preview'][src*='cookbook-hero']")
    end

    it "Shows the About section with three titled cards" do
      expect(page).to have_selector("[data-testid='app-landing-about-1'] h2", text: "Write It Down Once")
      expect(page).to have_selector("[data-testid='app-landing-about-2'] h2", text: "Find Something to Cook")
      expect(page).to have_selector("[data-testid='app-landing-about-3'] h2", text: "Share What You Like")
    end

    it "Still shows the left nav, with its own link back to this page" do
      within("[data-testid='left-nav']") do
        expect(page).to have_link("Cookbook", href: cookbook_path)
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows no other app's left nav links" do
      visit cookbook_path
      within("[data-testid='left-nav']") do
        expect(page).not_to have_link("Chronicle", href: chronicle_path)
        expect(page).not_to have_link("Occasions", href: event_tracker_path)
      end
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Is reachable from the 'Apps' menu" do
      visit root_path
      click_button "Apps"
      click_link "Cookbook"
      expect(page).to have_current_path(cookbook_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Is public: a guest sees it without signing in" do
      visit cookbook_path
      expect(page).to have_current_path(cookbook_path)
      expect(page).to have_link("Sign In", href: new_session_path)
    end
  end
end
