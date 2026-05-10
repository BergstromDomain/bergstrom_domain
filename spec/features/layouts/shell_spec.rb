# spec/features/layout_spec.rb
require "rails_helper"

RSpec.describe "Layout shell", type: :feature do
  let(:charlie)      { create(:user, role: :content_creator) }    
  
  describe "When viewing as 'Gary Guest'" do
    it "Renders the top navigation bar" do
      visit root_path
      expect(page).to have_css("[data-testid='top-nav']")
    end

    it "Renders the footer" do
      visit root_path
      expect(page).to have_css("[data-testid='footer']")
    end
  end

  describe "When viewing as 'Charlie Content Creator'" do
    before { sign_in_as(charlie) }

    it "Renders the top navigation bar" do
      visit root_path
      expect(page).to have_css("[data-testid='top-nav']")
    end

    it "Renders the footer" do
      visit root_path
      expect(page).to have_css("[data-testid='footer']")
    end
  end
end
