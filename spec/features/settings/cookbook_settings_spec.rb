# spec/features/settings/cookbook_settings_spec.rb
require "rails_helper"

RSpec.describe "Cookbook Settings", type: :feature do
  let(:uno)      { create(:user, first_name: "Uno", last_name: "User") }
  let!(:english) { create(:language, name: "English", code: "en", flag: "🇬🇧") }
  let!(:swedish) { create(:language, name: "Swedish", code: "sv", flag: "🇸🇪") }

  describe "Happy Path" do
    before do
      sign_in_as(uno)
      visit cookbook_settings_path
    end

    it "Renders the 'Cookbook Settings' page" do
      expect(page).to have_selector("[data-testid='cookbook-settings-page']")
    end

    it "Offers Cookbook's existing pages as 'Start Page' options" do
      expect(page).to have_select("Start Page", options: [
        "Cookbook", "Browse Recipes By Cuisine", "Browse Recipes By Food Type", "Filter Recipes",
        "Cuisines", "Food Types", "Languages"
      ])
    end

    it "Renders the 'Default Classification' field defaulting to 'Restricted'" do
      expect(page).to have_select("Classification", selected: "Restricted — visible only to me")
    end

    it "Pre-selects English as the 'Default Language' when none is saved" do
      expect(page).to have_select("Default Language", selected: "English", options: [ "English", "Swedish" ])
    end

    it "Saves all three settings" do
      select "Cuisines", from: "Start Page"
      select "Contacts — visible to my contacts", from: "Classification"
      select "Swedish", from: "Default Language"
      click_button "Save Cookbook Settings"

      expect(page).to have_current_path(cookbook_settings_path)
      expect(page).to have_content("Cookbook Settings updated.")
      expect(uno.app_settings_for("recipes")).to have_attributes(
        start_page: "cuisines", default_classification: "contacts", default_language: swedish
      )
    end

    it "Shows the saved Language on the next visit" do
      select "Swedish", from: "Default Language"
      click_button "Save Cookbook Settings"
      visit cookbook_settings_path
      expect(page).to have_select("Default Language", selected: "Swedish")
    end
  end

  describe "Negative Path" do
    it "Redirects 'Gary Guest' to the 'Sign-In' page" do
      visit cookbook_settings_path
      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "Alternative Paths" do
    it "Is linked from the Settings left nav, between Chronicle and Occasions" do
      sign_in_as(uno)
      visit settings_path
      within("[data-testid='left-nav']") do
        expect(page).to have_link("Cookbook Settings", href: cookbook_settings_path)
        links = all(".left-nav-link span").map(&:text)
        expect(links.index("Chronicle Settings")).to be < links.index("Cookbook Settings")
        expect(links.index("Cookbook Settings")).to be < links.index("Occasions Settings")
      end
    end
  end

  describe "Edge Cases" do
    it "Asks for a Language when no English Language exists and none is saved" do
      english.destroy!
      sign_in_as(uno)
      visit cookbook_settings_path
      expect(page).to have_select("Default Language", options: [ "Select a Language", "Swedish" ])
      expect(find("[data-testid='cookbook-settings-default-language-field']").value).to eq("")
    end

    it "Does not save any changes when the 'Cancel' button is clicked" do
      sign_in_as(uno)
      visit cookbook_settings_path
      select "Swedish", from: "Default Language"
      find("[data-testid='cookbook-settings-cancel']").click

      expect(page).to have_current_path(settings_path)
      expect(uno.app_settings_for("recipes").default_language).to be_nil
    end
  end
end
