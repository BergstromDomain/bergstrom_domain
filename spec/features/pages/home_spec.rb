# spec/features/pages/home_spec.rb
require "rails_helper"

RSpec.describe "Home page", type: :feature do
  describe "Happy path" do
    it "Renders the 'Sign Up' button for an unauthenticated visitor" do
      visit root_path
      expect(page).to have_selector("[data-testid='home-sign-up']")
    end
  end
end
