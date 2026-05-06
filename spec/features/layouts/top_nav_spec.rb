# spec/features/layouts/top_nav_spec.rb
require "rails_helper"

RSpec.describe "Top navigation bar", type: :feature do
  #                                                               # Gary Guest - An unauthorised visitor of the site
  let(:uno)          { create(:user) }                            # Uno User - A signed in user
  # let(:ulrika)       { create(:user) }                          # Ulrika User - A signed in user - NOTE: Not required for this spec
  let(:charlie)      { create(:user, role: :content_creator) }    # Charlie Content Creator - A signed in user with the Content Creator user role
  # let(:chris)        { create(:user, role: :content_creator) }  # Chris Content Creator - A signed in user with the Content Creator user role - NOTE: Not required for this spec
  # let(:curtis)       { create(:user, role: :content_creator) }  # Curtis the Content Creator - A signed in user with the Content Creator user role - NOTE: Not required for this spec
  let(:adam)         { create(:user, role: :administrator) }      # Adam Admin - A signed in user with the Admin user role
  let(:sam)          { create(:user, role: :system_admin) }       # Sam SysAdmin - A signed in user with the System Administrator user role

  shared_examples "Common nav links" do
    it "Shows the 'Home' link" do
      expect(page).to have_link("Home", href: root_path)
    end

    it "Shows the 'Apps' dropdown menu" do
      expect(page).to have_button("Apps")
    end

    it "Shows the 'Info' dropdown menu" do
      expect(page).to have_button("Info")
    end
  end

  context "When viewing as 'Gary Guest'" do
    before { visit root_path }

    include_examples "Common nav links"

    it "Shows 'Event Tracker' link in the 'Apps' dropdown menu" do
      click_button "Apps"
      expect(page).to have_link("Event Tracker", href: events_path)
    end

    it "Shows 'Blog Posts' link in the 'Apps' dropdown menu" do
      click_button "Apps"
      expect(page).to have_link("Blog Posts", href: blog_posts_path)
    end

    it "Shows 'About' link in the 'Info' dropdown menu" do
      click_button "Info"
      expect(page).to have_link("About", href: about_path)
    end

    it "Shows 'Contact' link in 'Info' dropdown menu" do
      click_button "Info"
      expect(page).to have_link("Contact", href: contact_path)
    end

    it "Does not show the 'System Admin' dropdown menu" do
      expect(page).not_to have_button("System Admin")
    end

    it "Shows the 'Sign In' button" do
      expect(page).to have_link("Sign In", href: new_session_path)
    end

    it "Does not show 'User Thumbnail' dropdown menu" do
      expect(page).not_to have_selector("[data-testid='user-thumbnail-button']")
    end

    it "Does not show 'Sign Out' link in the 'User Thumbnail' dropdown menu" do
      expect(page).not_to have_button("Sign Out")
    end

    it "Does not show 'User Settings' link in the 'User Thumbnail' dropdown menu" do
      expect(page).not_to have_button("User Settings")
    end
  end

  context "When viewing as 'Uno User'" do
    before do
      sign_in_as(uno)
      visit root_path
    end

    include_examples "Common nav links"

    it "Shows 'Event Tracker' link in the 'Apps' dropdown menu" do
      click_button "Apps"
      expect(page).to have_link("Event Tracker", href: events_path)
    end

    it "Shows 'Blog Posts' link in the 'Apps' dropdown menu" do
      click_button "Apps"
      expect(page).to have_link("Blog Posts", href: blog_posts_path)
    end

    it "Shows 'About' link in the 'Info' dropdown menu" do
      click_button "Info"
      expect(page).to have_link("About", href: about_path)
    end

    it "Shows 'Contact' link in 'Info' dropdown menu" do
      click_button "Info"
      expect(page).to have_link("Contact", href: contact_path)
    end

    it "Does not show the 'System Admin' dropdown menu" do
      expect(page).not_to have_button("System Admin")
    end

    it "Does not shows the 'Sign In' button" do
      expect(page).not_to have_link("Sign In", href: new_session_path)
    end

    it "Shows 'User Thumbnail' dropdown menu" do
      expect(page).to have_selector("[data-testid='user-thumbnail-button']")
      # TODO ensure it is Uno's thumbnail
    end

    it "Shows 'Sign Out' link in the 'User Thumbnail' dropdown menu" do
      expect(page).to have_button("Sign Out")
    end

    it "Shows 'User Settings' link in the 'User Thumbnail' dropdown menu" do
      expect(page).to have_link("User Settings")
    end
  end

  context "When viewing as 'Charlie Content Creator'" do
    before do
      sign_in_as(charlie)
      visit root_path
    end

    include_examples "Common nav links"

    it "Shows 'Event Tracker' link in the 'Apps' dropdown menu" do
      click_button "Apps"
      expect(page).to have_link("Event Tracker", href: events_path)
    end

    it "Shows 'Blog Posts' link in the 'Apps' dropdown menu" do
      click_button "Apps"
      expect(page).to have_link("Blog Posts", href: blog_posts_path)
    end

    it "Shows 'About' link in the 'Info' dropdown menu" do
      click_button "Info"
      expect(page).to have_link("About", href: about_path)
    end

    it "Shows 'Contact' link in 'Info' dropdown menu" do
      click_button "Info"
      expect(page).to have_link("Contact", href: contact_path)
    end

    it "Does not show the 'System Admin' dropdown menu" do
      expect(page).not_to have_button("System Admin")
    end

    it "Does not shows the 'Sign In' button" do
      expect(page).not_to have_link("Sign In", href: new_session_path)
    end

    it "Shows 'User Thumbnail' dropdown menu" do
      expect(page).to have_selector("[data-testid='user-thumbnail-button']")
      # TODO Ensure it is Charlie's image
    end

    it "Shows 'Sign Out' link in the 'User Thumbnail' dropdown menu" do
      expect(page).to have_button("Sign Out")
    end

    it "Shows 'User Settings' link in the 'User Thumbnail' dropdown menu" do
      expect(page).to have_link("User Settings")
    end
  end

  context "When viewing as 'Adam Admin'" do
    before do
      sign_in_as(charlie)
      visit root_path
    end

    include_examples "Common nav links"

    it "Shows 'Event Tracker' link in the 'Apps' dropdown menu" do
      click_button "Apps"
      expect(page).to have_link("Event Tracker", href: events_path)
    end

    it "Shows 'Blog Posts' link in the 'Apps' dropdown menu" do
      click_button "Apps"
      expect(page).to have_link("Blog Posts", href: blog_posts_path)
    end

    it "Shows 'About' link in the 'Info' dropdown menu" do
      click_button "Info"
      expect(page).to have_link("About", href: about_path)
    end

    it "Shows 'Contact' link in 'Info' dropdown menu" do
      click_button "Info"
      expect(page).to have_link("Contact", href: contact_path)
    end

    it "Does not show the 'System Admin' dropdown menu" do
      expect(page).not_to have_button("System Admin")
    end

    it "Does not shows the 'Sign In' button" do
      expect(page).not_to have_link("Sign In", href: new_session_path)
    end

    it "Shows 'User Thumbnail' dropdown menu" do
      expect(page).to have_selector("[data-testid='user-thumbnail-button']")
      # TODO Ensure it is Adam's image
    end

    it "Shows 'Sign Out' link in the 'User Thumbnail' dropdown menu" do
      expect(page).to have_button("Sign Out")
    end

    it "Shows 'User Settings' link in the 'User Thumbnail' dropdown menu" do
      expect(page).to have_link("User Settings")
    end
  end

  context "When viewing as 'Sam SysAdmin'" do
    before do
      sign_in_as(sam)
      visit root_path
    end

    include_examples "Common nav links"

    it "Shows 'Event Tracker' link in the 'Apps' dropdown menu" do
      click_button "Apps"
      expect(page).to have_link("Event Tracker", href: events_path)
    end

    it "Shows 'Blog Posts' link in the 'Apps' dropdown menu" do
      click_button "Apps"
      expect(page).to have_link("Blog Posts", href: blog_posts_path)
    end

    it "Shows 'About' link in the 'Info' dropdown menu" do
      click_button "Info"
      expect(page).to have_link("About", href: about_path)
    end

    it "Shows 'Contact' link in 'Info' dropdown menu" do
      click_button "Info"
      expect(page).to have_link("Contact", href: contact_path)
    end

    it "Shows the 'System Admin' dropdown menu" do
        expect(page).to have_button("System Admin")
    end

    it "Shows 'User Management' in 'System Admin' dropdown menu" do
      click_button "System Admin"
      expect(page).to have_text("User Management")
    end

    it "Shows 'App Management' in 'System Admin' dropdown menu" do
      click_button "System Admin"
      expect(page).to have_text("App Management")
    end

    it "Does not shows the 'Sign In' button" do
      expect(page).not_to have_link("Sign In", href: new_session_path)
    end

    it "Shows 'User Thumbnail' dropdown menu" do
      expect(page).to have_selector("[data-testid='user-thumbnail-button']")
      # TODO Ensure it is Adam's image
    end

    it "Shows 'Sign Out' link in the 'User Thumbnail' dropdown menu" do
      expect(page).to have_button("Sign Out")
    end

    it "Shows 'User Settings' link in the 'User Thumbnail' dropdown menu" do
      expect(page).to have_link("User Settings")
    end
  end

  context "Sign out" do
    before do
      sign_in_as(charlie)
      visit root_path
    end

    it "Signs the user out and redirects to root" do
      find("[data-testid='user-thumbnail-button']").click
      click_button "Sign Out"
      expect(page).to have_current_path(root_path)
      expect(page).to have_link("Sign In")
    end
  end
end
