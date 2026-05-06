# spec/features/auth/forgot_password_spec.rb
require "rails_helper"

RSpec.describe "Forgot Password", type: :feature do
  let!(:user) { create(:user, email_address: "bergstrom@example.com", password: "password123", password_confirmation: "password123") }

  describe "Happy path" do
    it "Renders the page heading" do
      visit new_password_path
      expect(page).to have_selector("h1.page-title", text: "Forgot Password")
    end

    it "Renders the email panel" do
      visit new_password_path
      expect(page).to have_selector("[data-testid='forgot-password-panel']")
    end

    it "Renders the email field" do
      visit new_password_path
      expect(page).to have_field("Email address")
    end

    it "Renders the 'Send Reset Link' button" do
      visit new_password_path
      expect(page).to have_button("Send Reset Link")
    end

    it "Renders the 'Cancel' button" do
      visit new_password_path
      have_link("Cancel", href: new_session_path)
    end

    it "Shows a notice after submitting a valid email" do
      visit new_password_path
      fill_in "Email address", with: "bergstrom@example.com"
      click_button "Send Reset Link"
      expect(page).to have_selector("[data-testid='flash-notice']")
    end
  end

  describe "Negative path" do
    it "Shows a notice even for an unknown email (no enumeration)" do
      visit new_password_path
      fill_in "Email address", with: "unknown@example.com"
      click_button "Send Reset Link"
      expect(page).to have_selector("[data-testid='flash-notice']")
    end
  end

  describe "Alternative path" do
    it "renders the page for an already-signed-in user" do
      sign_in_as(user)
      visit new_password_path
      expect(page).to have_field("Email address")
    end
  end

  describe "Edge cases" do
    it "Shows the helper text explaining what happens next" do
      visit new_password_path
      expect(page).to have_selector("[data-testid='reset-helper-text']")
    end
  end
end
