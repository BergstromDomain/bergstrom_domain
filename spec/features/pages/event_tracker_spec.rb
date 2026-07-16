# spec/features/pages/event_tracker_spec.rb
require "rails_helper"

RSpec.describe "Event Tracker landing page", type: :feature do
  describe "Happy Path" do
    before { visit event_tracker_path }

    it "Renders via the shared app landing template" do
      expect(page).to have_selector("[data-testid='app-landing']")
    end

    it "Shows the About section with three cards" do
      expect(page).to have_selector("[data-testid='app-landing-about-1']", text: "birthdays")
      expect(page).to have_selector("[data-testid='app-landing-about-2']", text: "Signed-in users")
      expect(page).to have_selector("[data-testid='app-landing-about-3']", text: "day, week, or month")
    end

    it "Still shows the left nav, with its own link back to this page" do
      expect(page).to have_selector("[data-testid='left-nav']")
      within("[data-testid='left-nav']") do
        expect(page).to have_link("Event Tracker", href: event_tracker_path)
      end
    end
  end
end
