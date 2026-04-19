# spec/features/layout_spec.rb
require "rails_helper"

RSpec.describe "Layout shell", type: :feature do
  describe "unauthenticated user" do
    it "renders the top navigation bar" do
      visit root_path
      expect(page).to have_css("[data-testid='top-nav']")
    end

    it "renders the footer" do
      visit root_path
      expect(page).to have_css("[data-testid='footer']")
    end
  end

  describe "authenticated user" do
    let(:user) { create(:user) }

    before { sign_in_as(user) }

    it "renders the top navigation bar" do
      visit root_path
      expect(page).to have_css("[data-testid='top-nav']")
    end

    it "renders the footer" do
      visit root_path
      expect(page).to have_css("[data-testid='footer']")
    end
  end
end
