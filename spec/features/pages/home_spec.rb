# spec/features/pages/home_spec.rb
require "rails_helper"

RSpec.describe "Home page", type: :feature do
  describe "Happy Path" do
    before { visit root_path }

    it "Renders the grid layout with the central portrait" do
      expect(page).to have_selector("[data-testid='home-grid']")
      expect(page).to have_selector("[data-testid='home-portrait']")
    end

    it "Shows the 'Hero' quadrant" do
      expect(page).to have_selector("[data-testid='home-hero']")
    end

    it "shows the 'Friends & Family' quadrant" do
      expect(page).to have_selector("[data-testid='home-audience-friends']")
    end

    it "Shows the 'Sign Up' button linking to the 'Sign Up' page" do
      expect(page).to have_link("Sign Up", href: sign_up_path)
      expect(page).to have_selector("[data-testid='home-sign-up']")
    end

    it "Shows the 'Recruiters' quadrant" do
      expect(page).to have_selector("[data-testid='home-audience-recruiters']")
    end

    it "Shows the 'Guests' quadrant" do
      expect(page).to have_selector("[data-testid='home-audience-guests']")
    end
  end
end
