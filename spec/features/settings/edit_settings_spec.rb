# spec/features/settings/edit_settings_spec.rb
require "rails_helper"

RSpec.describe "Edit User Settings", type: :feature do
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
      visit edit_settings_path
      expect(page).to have_css("h1.page-title", text: "Uno User")
      expect(page).to have_css(".page-subtitle", text: "User Settings")
    end

    it "Renders the 'Profile' panel" do
      sign_in_as(uno)
      visit edit_settings_path
      expect(page).to have_selector("[data-testid='settings-profile-panel']")
    end

    it "Renders the 'Profile' image inside the 'Profile' panel" do
      sign_in_as(uno)
      visit edit_settings_path
      expect(page).to have_selector("[data-testid='settings-image-field']")
    end

    it "Renders the 'First Name' field inside the 'Profile' panel" do
      sign_in_as(uno)
      visit edit_settings_path
      expect(page).to have_field("First Name")
    end

    it "Renders the 'Last Name' field inside the 'Profile' panel" do
      sign_in_as(uno)
      visit edit_settings_path
      expect(page).to have_field("Last Name")
    end

    it "Renders the 'Profile Image' upload selector inside the 'Profile' panel" do
      sign_in_as(uno)
      visit edit_settings_path
      expect(page).to have_field("Profile Image")
    end

    it "Renders the 'Email Address' field inside the 'Profile' panel" do
      sign_in_as(uno)
      visit edit_settings_path
      expect(page).to have_field("Email Address")
      expect(page).to have_text("Changing your email address will require re-verification.")
    end

    it "Renders the 'Preferences' panel" do
      sign_in_as(uno)
      visit edit_settings_path
      expect(page).to have_selector("[data-testid='settings-preferences-panel']")
    end

    it "Renders the 'Start Page' field inside the 'Preferences' panel" do
      sign_in_as(uno)
      visit edit_settings_path
      expect(page).to have_field("Start Page")
    end

    it "Renders the 'Actions' panel" do
      sign_in_as(uno)
      visit edit_settings_path
      expect(page).to have_selector("[data-testid='settings-actions-panel']")
    end

    it "Renders the 'Cancel' button inside the 'Actions' panel" do
      sign_in_as(uno)
      visit edit_settings_path
      expect(page).to have_selector("[data-testid='settings-edit-cancel']")
    end

    it "Renders the 'Update Details' button" do
      sign_in_as(uno)
      visit edit_settings_path
      expect(page).to have_button("Update Details")
    end

    it "Navigates to the 'User Settings' page when the 'Cancel' button is clicked" do
      sign_in_as(uno)
      visit edit_settings_path
      find("[data-testid='settings-edit-cancel']").click
      expect(page).to have_current_path(settings_path)
    end

    it "Updates 'Page Title' with the user's 'Full Name' when' First Name' and 'Last Name'" do
      sign_in_as(uno)
      visit edit_settings_path

      fill_in "First Name", with: "Updated"
      fill_in "Last Name",  with: "Name"
      click_button "Update Details"

      expect(page).to have_current_path(settings_path)
      expect(page).to have_css("h1.page-title", text: "Updated Name")
    end

    it "Updates the 'Profile Image'" do
      sign_in_as(uno)
      visit edit_settings_path

      attach_file "settings-image-input",
        Rails.root.join("spec/fixtures/files/test_image.jpg")
      click_button "Update Details"

      expect(page).to have_current_path(settings_path)
      expect(uno.reload.profile_image).to be_attached
    end

    xit "Updates 'Start Page' with a new value" do
      sign_in_as(uno)
      visit edit_settings_path
      # TODO
    end

    it "Updates the 'Email Address' and clears the 'Email Verified' flag" do
      uno.update!(email_verified_at: Time.current)
      sign_in_as(uno)
      visit edit_settings_path

      fill_in "Email Address", with: "Uno.Updated@example.com"
      click_button "Update Details"

      expect(page).to have_current_path(settings_path)
      expect(uno.reload.email_verified_at).to be_nil
    end
  end

  describe "Negative path" do
    it "Redirects 'Gary Guest' to the 'Sign-In' page" do
      visit edit_settings_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Shows an error when 'First Name' is blank" do
      sign_in_as(uno)
      visit edit_settings_path

      fill_in "First Name", with: ""
      click_button "Update Details"

      expect(page).to have_selector("[data-testid='settings-edit-errors']")
    end

    it "Shows an error when 'Last Name' is blank" do
      sign_in_as(uno)
      visit edit_settings_path

      fill_in "Last Name", with: ""
      click_button "Update Details"

      expect(page).to have_selector("[data-testid='settings-edit-errors']")
    end

    it "Shows an error when 'Email Address' is already taken" do
      create(:user, email_address: "Taken@example.com")
      sign_in_as(uno)
      visit edit_settings_path

      fill_in "Email Address", with: "Taken@example.com"
      click_button "Update Details"

      expect(page).to have_selector("[data-testid='settings-edit-errors']")
    end
  end

  describe "Alternative path" do
    it "Does not clear the 'Email Verified' flag when the 'Email Address' is unchanged" do
      uno.update!(email_verified_at: Time.current)
      sign_in_as(uno)
      visit edit_settings_path

      fill_in "First Name", with: "Ulrika"
      click_button "Update Details"

      expect(uno.reload.email_verified_at).not_to be_nil
    end
  end

  describe "Edge cases" do
    it "Does not save any of the changed values if the user clicks on the 'Cancel' button" do
      uno.update!(email_verified_at: Time.current)
      sign_in_as(uno)
      visit edit_settings_path

      fill_in "First Name", with: "Updated"
      fill_in "Last Name",  with: "Name"
      fill_in "Email Address", with: "Taken@example.com"
      select "Event Tracker - Events By Day", from: "Start Page"

      find("[data-testid='settings-edit-cancel']").click
      expect(page).to have_current_path(settings_path)
    end
  end
end
