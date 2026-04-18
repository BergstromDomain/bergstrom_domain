# spec/features/pages_spec.rb
require "rails_helper"

RSpec.describe "Static pages", type: :feature do
  describe "Home page" do
    it "renders without error" do
      visit root_path
      expect(page).to have_http_status(:ok)
    end

    it "does not render the left navigation bar" do
      visit root_path
      expect(page).not_to have_css("[data-testid='left-nav']")
    end
  end

  describe "About page" do
    it "renders without error" do
      visit about_path
      expect(page).to have_http_status(:ok)
    end

    it "does not render the left navigation bar" do
      visit about_path
      expect(page).not_to have_css("[data-testid='left-nav']")
    end
  end

  describe "Contact page" do
    it "renders without error" do
      visit contact_path
      expect(page).to have_http_status(:ok)
    end

    it "does not render the left navigation bar" do
      visit contact_path
      expect(page).not_to have_css("[data-testid='left-nav']")
    end
  end
end
