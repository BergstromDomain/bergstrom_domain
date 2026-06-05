# spec/features/settings/show_settings_spec.rb
require "rails_helper"

RSpec.describe "User Settings", type: :feature do
  let(:uno) do
    create(:user,
      first_name:    "Uno",
      last_name:     "User",
      email_address: "Uno.User@example.com"
    )
  end

  describe "Happy path" do
    it "Renders the 'Page Title' with the user's 'Full Name' and 'User Settings' subtitle" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("h1.page-title", text: "Uno User")
      expect(page).to have_selector(".page-subtitle", text: "User Settings")
    end

    it "Renders the 'Profile' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-profile-panel']")
    end

    it "Renders the 'Profile' image inside the 'Profile' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-image-field']")
    end

    it "Renders the 'Email Address' field inside the 'Profile' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-email']")
    end

    it "Renders the 'Unverified Email' icon inside the 'Profile' panelwhen the 'Email Address' is not verified" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-email-unverified']")
    end

    it "Renders the 'Verified Email' icon inside the 'Profile' panel when the 'Email Address' is verified" do
      uno.update!(email_verified_at: Time.current)
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-email-verified']")
    end

    it "Renders the 'Verify Email' button inside the 'Profile' panel when the 'Email Address' is not verified" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-verify-email-button']")
    end

    it "Does not render the 'Verify Email' button inside the 'Profile' panel when the 'Email Address' is verified" do
      uno.update!(email_verified_at: Time.current)
      sign_in_as(uno)
      visit settings_path
      expect(page).not_to have_selector("[data-testid='settings-verify-email-button']")
    end

    it "Sends a 'Verification Email' when the 'Verify Email' button is clicked" do
      sign_in_as(uno)
      visit settings_path
      find("[data-testid='settings-verify-email-button']").click
      expect(page).to have_selector("[data-testid='flash-notice']")
    end

    it "Renders the 'Preferences' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-preferences-panel']")
    end

    it "Renders the 'Start Page' field inside the 'Preferences' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-start-page']")
    end

    it "Renders the 'Change Password' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-password-panel']")
    end

    it "Renders the 'Current Password' field inside the 'Change Password' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-current-password']")
    end

    it "Renders the 'New Password' field inside the 'Change Password' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-new-password']")
    end

    it "Renders the 'Password Confirmation' field inside the 'Change Password' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-password-confirmation']")
    end

    it "Renders the 'Update Password' button inside the 'Change Password' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-update-password-button']")
    end

    it "Updates the 'Current Password' with the 'New Password' when the the 'New Password' and the 'Password Confirmation' match" do
      sign_in_as(uno)
      visit settings_path

      within "[data-testid='settings-password-panel']" do
        fill_in "Current Password",      with: "password123"
        fill_in "New Password",          with: "newpassword456"
        fill_in "Password Confirmation", with: "newpassword456"
        click_button "Update Password"
      end

      expect(page).to have_current_path(settings_path)
      expect(page).to have_selector("[data-testid='flash-notice']")
    end

    it "Renders the 'Actions' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-actions-panel']")
    end

    it "Renders the 'Back to Home' button inside the 'Actions' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-back-link']")
    end

    it "Renders the 'Edit Details' button inside the 'Actions' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-edit-link']")
    end

    it "Renders the 'Delete Account' button inside the 'Actions' panel" do
      sign_in_as(uno)
      visit settings_path
      expect(page).to have_selector("[data-testid='settings-delete-button']")
    end

    it "Navigates to the 'Home' page when the button 'Back to Home' is clicked" do
      sign_in_as(uno)
      visit settings_path
      find("[data-testid='settings-back-link']").click
      expect(page).to have_current_path(root_path)
    end

    it "Navigates to the 'Edit Settings' page when the button 'Edit Details' is clicked" do
      sign_in_as(uno)
      visit settings_path
      find("[data-testid='settings-edit-link']").click
      expect(page).to have_current_path(edit_settings_path)
    end

    it "Suspends the 'User Account' and redirects to 'Home' when 'Delete Account' is confirmed" do
      sign_in_as(uno)
      visit settings_path
      find("[data-testid='settings-delete-button']").click
      expect(page).to have_current_path(root_path)
      expect(page).to have_selector("[data-testid='flash-notice']")
      expect(uno.reload.status).to eq("suspended")
    end
  end

  describe "Negative path" do
    it "Redirects 'Gary Guest' to the 'Sign-In' page" do
      visit settings_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Shows an error when the 'Current Password' is wrong" do
      sign_in_as(uno)
      visit settings_path

      within "[data-testid='settings-password-panel']" do
        fill_in "Current Password",      with: "wrongpassword"
        fill_in "New Password",          with: "newpassword456"
        fill_in "Password Confirmation", with: "newpassword456"
        click_button "Update Password"
      end

      expect(page).to have_selector("[data-testid='settings-password-errors']")
    end

    it "Shows an error when 'New Password' and 'Password Confirmation' does not match" do
      sign_in_as(uno)
      visit settings_path

      within "[data-testid='settings-password-panel']" do
        fill_in "Current Password",      with: "password123"
        fill_in "New Password",          with: "newpassword456"
        fill_in "Password Confirmation", with: "different"
        click_button "Update Password"
      end

      expect(page).to have_selector("[data-testid='settings-password-errors']")
    end
  end

  describe "Alternative path" do
    it "Renders the 'User Settings' page for 'Sam SysAdmin'" do
      sam = create(:user,
        role:          :system_admin,
        first_name:    "Sam",
        last_name:     "SysAdmin",
        email_address: "Sam.SysAdmin@example.com"
      )
      sign_in_as(sam)
      visit settings_path
      expect(page).to have_selector("h1.page-title", text: "Sam SysAdmin")
    end
  end

  describe "Edge cases" do
    xit "Returns to the 'User Settings' page if the user cancels the deletion confirmation" do
      # Requires JS driver — data-turbo-confirm dialog cannot be cancelled in Rack test driver.
      # Revisit when JS driver session isolation issue is resolved (Post #19+).
    end
  end
end
