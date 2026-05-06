# spec/features/auth/reset_password_spec.rb
require "rails_helper"

RSpec.describe "Reset Password", type: :feature do
  # The reset flow requires a password reset token. We generate one directly.
  let!(:user) { create(:user, email_address: "james@example.com", password: "password123") }
  let(:token) { user.password_reset_token }

  describe "Happy path" do
    it "Renders the page heading" do
      visit edit_password_path(token)
      expect(page).to have_selector("h1.page-title", text: "Reset Password")
    end

    it "Renders the reset panel" do
      visit edit_password_path(token)
      expect(page).to have_selector("[data-testid='reset-password-panel']")
    end

    it "Renders the new password field" do
      visit edit_password_path(token)
      expect(page).to have_field("New password")
    end

    it "Renders the confirm password field" do
      visit edit_password_path(token)
      expect(page).to have_field("Confirm password")
    end

    it "Renders the 'Cancel' button" do
      visit edit_password_path(token)
      expect(page).to have_link("Cancel", href: root_path)
    end

    it "Renders the 'Reset Password' button" do
      visit edit_password_path(token)
      expect(page).to have_button("Reset Password")
    end

    it "Resets the password and redirects to the 'Sign In' page" do
      visit edit_password_path(token)
      fill_in "New password", with: "newpassword456"
      fill_in "Confirm password", with: "newpassword456"
      click_button "Reset Password"
      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "Negative path" do
    it "Shows an alert when passwords do not match" do
      visit edit_password_path(token)
      fill_in "New password", with: "newpassword456"
      fill_in "Confirm password", with: "differentpassword"
      click_button "Reset Password"
      expect(page).to have_selector("[data-testid='flash-alert']")
    end
  end

  describe "Alternative path" do
    it "Shows an error for an invalid token" do
      visit edit_password_path("invalidtoken")
      expect(page).to have_selector("[data-testid='flash-alert']")
    end
  end

  describe "Edge cases" do
    xit "Shows an alert when the new password is blank" do
      visit edit_password_path(token)
      fill_in "Confirm password", with: "newpassword456"
      click_button "Reset Password"
      expect(page).to have_selector("[data-testid='flash-alert']")
    end
  end
end
