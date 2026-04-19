# spec/features/layouts/top_nav_spec.rb
require "rails_helper"

RSpec.describe "Top navigation bar", type: :feature do
  let(:user)         { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }

  shared_examples "common nav links" do
    it "shows the Home link" do
      expect(page).to have_link("Home", href: root_path)
    end

    it "shows the Apps dropdown trigger" do
      expect(page).to have_button("Apps")
    end

    it "shows the Info dropdown trigger" do
      expect(page).to have_button("Info")
    end
  end

  context "when unauthenticated" do
    before { visit root_path }

    include_examples "common nav links"

    it "shows the Login button" do
      expect(page).to have_link("Login", href: new_session_path)
    end

    it "does not show sign out" do
      expect(page).not_to have_button("Sign Out")
    end

    it "does not show the System Admin dropdown" do
      expect(page).not_to have_button("System Admin")
    end

    it "shows Event Tracker link in Apps dropdown" do
      click_button "Apps"
      expect(page).to have_link("Event Tracker", href: events_path)
    end

    it "shows Blog Posts link in Apps dropdown" do
      click_button "Apps"
      expect(page).to have_link("Blog Posts", href: blog_posts_path)
    end

    it "shows About link in Info dropdown" do
      click_button "Info"
      expect(page).to have_link("About", href: about_path)
    end

    it "shows Contact link in Info dropdown" do
      click_button "Info"
      expect(page).to have_link("Contact", href: contact_path)
    end
  end

  context "when authenticated as a regular user" do
    before do
      sign_in_as(user)
      visit root_path
    end

    include_examples "common nav links"

    it "shows the sign out button" do
      expect(page).to have_button("Sign Out")
    end

    it "does not show the Login button" do
      expect(page).not_to have_link("Login")
    end

    it "does not show the System Admin dropdown" do
      expect(page).not_to have_button("System Admin")
    end
  end

  context "when authenticated as a system admin" do
    before do
        sign_in_as(system_admin)
        visit root_path
    end

    include_examples "common nav links"

    it "shows the System Admin dropdown trigger" do
        expect(page).to have_button("System Admin")
    end

    it "shows User Management in System Admin dropdown" do
      click_button "System Admin"
      expect(page).to have_text("User Management")
    end

    it "shows App Management in System Admin dropdown" do
      click_button "System Admin"
      expect(page).to have_text("App Management")
    end
  end

  context "sign out" do
    before do
      sign_in_as(user)
      visit root_path
    end

    it "signs the user out and redirects to root" do
      click_button "Sign Out"
      expect(page).to have_current_path(root_path)
      expect(page).to have_link("Login")
    end
  end
end
