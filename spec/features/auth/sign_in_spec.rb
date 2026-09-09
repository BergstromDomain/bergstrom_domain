# spec/features/auth/sign_in_spec.rb
require "rails_helper"

RSpec.describe "Sign In", type: :feature do
  let!(:user) { create(:user, email_address: "bergstrom@example.com", password: "password123", password_confirmation: "password123") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Signs in with valid credentials and redirects to root" do
      visit new_session_path
      expect(page).to have_selector("h1.page-title", text: "Sign In")
      expect(page).to have_selector("[data-testid='sign-in-panel']")
      fill_in "Email address", with: "bergstrom@example.com"
      fill_in "Password",      with: "password123"
      click_button "Sign In"
      expect(page).to have_current_path(root_path)
    end

    it "Signs in and redirects to the originally requested URL" do
      visit new_event_path
      fill_in "Email address", with: "bergstrom@example.com"
      fill_in "Password",      with: "password123"
      click_button "Sign In"
      expect(page).to have_current_path(new_event_path)
    end

    it "Renders the email field" do
      visit new_session_path
      expect(page).to have_field("Email address")
    end

    it "Renders the password field" do
      visit new_session_path
      expect(page).to have_field("Password")
    end

    it "Renders the 'Forgot password?' link" do
      visit new_session_path
      expect(page).to have_link("Forgot password?", href: new_password_path)
    end

    it "Renders the 'Cancel' button" do
      visit new_session_path
      expect(page).to have_link("Cancel", href: root_path)
    end

    it "Renders the 'Sign In' button on the right" do
      visit new_session_path
      expect(page).to have_button("Sign In")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Stays on the sign-in page with an incorrect password" do
      visit new_session_path
      fill_in "Email address", with: "bergstrom@example.com"
      fill_in "Password",      with: "wrong-password"
      click_button "Sign In"
      expect(page).to have_current_path(new_session_path)
    end

    it "Stays on the sign-in page with an incorrect email address" do
      visit new_session_path
      fill_in "Email address", with: "nobody@example.com"
      fill_in "Password",      with: "password123"
      click_button "Sign In"
      expect(page).to have_current_path(new_session_path)
    end

    it "Stays on the sign-in page with blank credentials" do
      visit new_session_path
      fill_in "Email address", with: ""
      fill_in "Password",      with: ""
      click_button "Sign In"
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Signs in with email address in a different case" do
      visit new_session_path
      fill_in "Email address", with: "BERGSTROM@EXAMPLE.COM"
      fill_in "Password",      with: "password123"
      click_button "Sign In"
      expect(page).to have_current_path(root_path)
    end

    it "Redirects to the Occasions landing page when the user's Start Page is 'event_tracker'" do
      user.update!(start_page: "event_tracker")
      visit new_session_path
      fill_in "Email address", with: "bergstrom@example.com"
      fill_in "Password",      with: "password123"
      click_button "Sign In"
      expect(page).to have_current_path(event_tracker_path)
    end

    it "Redirects to the Chronicle landing page when the user's Start Page is 'blog_posts'" do
      user.update!(start_page: "blog_posts")
      visit new_session_path
      fill_in "Email address", with: "bergstrom@example.com"
      fill_in "Password",      with: "password123"
      click_button "Sign In"
      expect(page).to have_current_path(chronicle_path)
    end

    it "Redirects to the Chronicle sub-page set in Chronicle Settings" do
      user.update!(start_page: "blog_posts")
      user.app_settings_for("blog_posts").update!(start_page: "blog_categories")
      visit new_session_path
      fill_in "Email address", with: "bergstrom@example.com"
      fill_in "Password",      with: "password123"
      click_button "Sign In"
      expect(page).to have_current_path(blog_categories_path)
    end

    it "Redirects to the Occasions sub-page set in Occasions Settings" do
      user.update!(start_page: "event_tracker")
      user.app_settings_for("event_tracker").update!(start_page: "people")
      visit new_session_path
      fill_in "Email address", with: "bergstrom@example.com"
      fill_in "Password",      with: "password123"
      click_button "Sign In"
      expect(page).to have_current_path(people_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Does not redirect an already-signed-in user visiting sign in" do
      sign_in_as(user)
      visit new_session_path
      expect(page).to have_button("Sign In")
    end
  end
end
