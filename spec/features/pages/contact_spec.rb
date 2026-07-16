# spec/features/pages/contact_spec.rb
require "rails_helper"

RSpec.describe "Contact page", type: :feature do
  describe "Happy Path" do
    before { visit contact_path }

    it "Renders the 'Contact Me' heading" do
      expect(page).to have_selector("h1", text: "Contact Me")
    end

    it "Shows the Brisbane location" do
      expect(page).to have_selector("[data-testid='contact-location']", text: "Brisbane, QLD, Australia")
    end

    it "Shows the bergstromdomain.com contact email, not a personal address" do
      expect(page).to have_selector("[data-testid='contact-email']", text: "niklas@bergstromdomain.com")
      expect(page).not_to have_text("gmail.com")
    end

    it "Links to LinkedIn" do
      expect(page).to have_selector(
        "[data-testid='contact-linkedin'] a[href='https://www.linkedin.com/in/niklasbergstrom/']"
      )
    end
  end
end
