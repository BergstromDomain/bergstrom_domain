# spec/features/layout_spec.rb
require "rails_helper"

RSpec.describe "Layout shell", type: :feature do
  #                                                       # Gary Guest - An unauthorised visitor of the site
  # let(:uno)          { create(:user) }                    # Uno User - A signed in user - NOTE: Not required for this spec
  # let(:ulrika)       { create(:user) }                    # Ulrika User - A signed in user - NOTE: Not required for this spec
  let(:charlie)      { create(:user, role: :content_creator) }  # Charlie Content Creator - A signed in user with the Content Creator user role
  # let(:chris)        { create(:user, role: :content_creator) }  # Chris Content Creator - A signed in user with the Content Creator user role - NOTE: Not required for this spec
  # let(:curtis)       { create(:user, role: :content_creator) }  # Curtis the Content Creator - A signed in user with the Content Creator user role - NOTE: Not required for this spec
  # let(:adam)         { create(:user, role: :administrator) }    # Adam Admin - A signed in user with the Admin user role - NOTE: Not required for this spec
  # let(:sam)          { create(:user, role: :system_admin) }     # Sam SysAdmin - A signed in user with the System Administrator user role - NOTE: Not required for this spec

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
