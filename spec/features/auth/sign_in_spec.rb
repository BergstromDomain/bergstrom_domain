# spec/features/auth/sign_in_spec.rb
require "rails_helper"

RSpec.describe "Sign In", type: :feature do
  let!(:user) { create(:user, email_address: "bergstrom@example.com", password: "password123", password_confirmation: "password123") }

  describe "Happy path" do
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

  describe "Negative path" do
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

  describe "Alternative path" do
    it "Signs in with email address in a different case" do
      visit new_session_path
      fill_in "Email address", with: "BERGSTROM@EXAMPLE.COM"
      fill_in "Password",      with: "password123"
      click_button "Sign In"
      expect(page).to have_current_path(root_path)
    end
  end

  describe "Edge cases" do
    it "Does not redirect an already-signed-in user visiting sign in" do
      sign_in_as(user)
      visit new_session_path
      expect(page).to have_button("Sign In")
    end
  end
end
