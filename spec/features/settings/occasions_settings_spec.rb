# spec/features/settings/occasions_settings_spec.rb
require "rails_helper"

RSpec.describe "Occasions Settings", type: :feature do
  let(:uno) { create(:user, first_name: "Uno", last_name: "User") }

  describe "Happy path" do
    it "Renders the 'Occasions Settings' page for a signed-in user" do
      sign_in_as(uno)
      visit occasions_settings_path
      expect(page).to have_selector("[data-testid='occasions-settings-page']")
    end
  end

  describe "Negative path" do
    it "Redirects 'Gary Guest' to the 'Sign-In' page" do
      visit occasions_settings_path
      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "Alternative path" do
    it "Renders the 'Occasions Settings' page for 'Sam SysAdmin'" do
      sam = create(:user, role: :system_admin, first_name: "Sam", last_name: "SysAdmin")
      sign_in_as(sam)
      visit occasions_settings_path
      expect(page).to have_selector("[data-testid='occasions-settings-page']")
    end
  end

  describe "Edge cases" do
    xit "Prefills the 'Start Page' and 'Default Classification' fields with the user's saved values" do
      # Fields land in Block 5 — this page is scaffolding-only in Block 1.
    end
  end
end
