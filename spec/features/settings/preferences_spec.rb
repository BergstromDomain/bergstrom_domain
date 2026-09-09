# spec/features/settings/preferences_spec.rb
require "rails_helper"

RSpec.describe "Preferences", type: :feature do
  let(:uno) { create(:user, first_name: "Uno", last_name: "User") }

  describe "Happy Path" do
    it "Renders the 'Preferences' page for a signed-in user" do
      sign_in_as(uno)
      visit preferences_settings_path
      expect(page).to have_selector("[data-testid='preferences-page']")
    end

    it "Renders the 'Start Page' field with 'Home', 'Chronicle' and 'Occasions' options" do
      sign_in_as(uno)
      visit preferences_settings_path
      expect(page).to have_select("Start Page", options: [ "Home", "Chronicle", "Occasions" ])
    end

    it "Renders the 'Default Visibility' checkboxes, all checked by default" do
      sign_in_as(uno)
      visit preferences_settings_path
      expect(page).to have_checked_field("Restricted")
      expect(page).to have_checked_field("Contacts")
      expect(page).to have_checked_field("Unrestricted")
    end

    it "Renders the reworded 'Default Visibility' info text" do
      sign_in_as(uno)
      visit preferences_settings_path
      expect(page).to have_text("Which classifications to show by default when viewing records?")
    end

    it "Updates 'Start Page' with a new value" do
      sign_in_as(uno)
      visit preferences_settings_path

      select "Occasions", from: "Start Page"
      click_button "Save Preferences"

      expect(page).to have_current_path(preferences_settings_path)
      expect(uno.reload.start_page).to eq("event_tracker")
    end

    it "Updates 'Default Visibility' when a box is unchecked" do
      sign_in_as(uno)
      visit preferences_settings_path

      uncheck "Restricted"
      click_button "Save Preferences"

      expect(page).to have_current_path(preferences_settings_path)
      expect(uno.reload.default_classifications).to contain_exactly("contacts", "unrestricted")
    end

    it "Saves an empty 'Default Visibility' when every box is unchecked" do
      sign_in_as(uno)
      visit preferences_settings_path

      uncheck "Restricted"
      uncheck "Contacts"
      uncheck "Unrestricted"
      click_button "Save Preferences"

      expect(page).to have_current_path(preferences_settings_path)
      expect(uno.reload.default_classifications).to eq([])
    end
  end

  describe "Negative Path" do
    it "Redirects 'Gary Guest' to the 'Sign-In' page" do
      visit preferences_settings_path
      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "Alternative Paths" do
    it "Renders the 'Preferences' page for 'Sam SysAdmin'" do
      sam = create(:user, role: :system_admin, first_name: "Sam", last_name: "SysAdmin")
      sign_in_as(sam)
      visit preferences_settings_path
      expect(page).to have_selector("[data-testid='preferences-page']")
    end
  end

  describe "Edge Cases" do
    it "Does not save any changes when the 'Cancel' button is clicked" do
      sign_in_as(uno)
      visit preferences_settings_path

      select "Chronicle", from: "Start Page"
      find("[data-testid='preferences-cancel']").click

      expect(page).to have_current_path(settings_path)
      expect(uno.reload.start_page).to eq("home")
    end
  end
end
