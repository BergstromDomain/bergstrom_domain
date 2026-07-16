# spec/features/pages/about_spec.rb
require "rails_helper"

RSpec.describe "About page", type: :feature do
  describe "Happy Path" do
    before { visit about_path }

    it "Renders the heading" do
      expect(page).to have_selector("h1", text: "About")
    end

    it "Shows the photo" do
      expect(page).to have_selector("[data-testid='about-photo']")
    end

    it "Shows the professional bio" do
      expect(page).to have_selector("[data-testid='about-bio-1']", text: "Test Manager")
    end

    it "Shows the outdoors bio" do
      expect(page).to have_selector("[data-testid='about-bio-2']", text: "rock climbing")
    end

    it "Shows the building-in-public bio" do
      expect(page).to have_selector("[data-testid='about-bio-3']", text: "bergstromdomain.com")
    end
  end
end
