# spec/features/settings/chronicle_settings_spec.rb
require "rails_helper"

RSpec.describe "Chronicle Settings", type: :feature do
  let(:uno) { create(:user, first_name: "Uno", last_name: "User") }

  describe "Happy path" do
    it "Renders the 'Chronicle Settings' page for a signed-in user" do
      sign_in_as(uno)
      visit chronicle_settings_path
      expect(page).to have_selector("[data-testid='chronicle-settings-page']")
    end

    it "Renders the 'Start Page' field with Chronicle's own views as options" do
      sign_in_as(uno)
      visit chronicle_settings_path
      expect(page).to have_select("Start Page", options: [
        "Chronicle", "Browse Blog Posts", "Filter Blog Posts",
        "My Published Posts", "My Unpublished Posts", "Blog Categories"
      ])
    end

    it "Renders the 'Default Classification' field defaulting to 'Restricted'" do
      sign_in_as(uno)
      visit chronicle_settings_path
      expect(page).to have_select("Classification", selected: "Restricted — visible only to me")
    end

    it "Renders the reworded 'Default Classification' info text" do
      sign_in_as(uno)
      visit chronicle_settings_path
      expect(page).to have_text("Which classification to use as default when creating posts?")
    end

    it "Updates 'Start Page' with a new value" do
      sign_in_as(uno)
      visit chronicle_settings_path

      select "Blog Categories", from: "Start Page"
      click_button "Save Chronicle Settings"

      expect(page).to have_current_path(chronicle_settings_path)
      expect(uno.app_settings_for("blog_posts").start_page).to eq("blog_categories")
    end

    it "Updates 'Default Classification' with a new value" do
      sign_in_as(uno)
      visit chronicle_settings_path

      select "Unrestricted — visible to everyone", from: "Classification"
      click_button "Save Chronicle Settings"

      expect(page).to have_current_path(chronicle_settings_path)
      expect(uno.app_settings_for("blog_posts").default_classification).to eq("unrestricted")
    end

    it "Persists the setting across visits" do
      sign_in_as(uno)
      visit chronicle_settings_path
      select "Browse Blog Posts", from: "Start Page"
      click_button "Save Chronicle Settings"

      visit chronicle_settings_path
      expect(page).to have_select("Start Page", selected: "Browse Blog Posts")
    end
  end

  describe "Negative path" do
    it "Redirects 'Gary Guest' to the 'Sign-In' page" do
      visit chronicle_settings_path
      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "Alternative path" do
    it "Renders the 'Chronicle Settings' page for 'Sam SysAdmin'" do
      sam = create(:user, role: :system_admin, first_name: "Sam", last_name: "SysAdmin")
      sign_in_as(sam)
      visit chronicle_settings_path
      expect(page).to have_selector("[data-testid='chronicle-settings-page']")
    end
  end

  describe "Edge cases" do
    it "Does not save any changes when the 'Cancel' button is clicked" do
      sign_in_as(uno)
      visit chronicle_settings_path

      select "Blog Categories", from: "Start Page"
      find("[data-testid='chronicle-settings-cancel']").click

      expect(page).to have_current_path(settings_path)
      expect(uno.app_settings_for("blog_posts").start_page).to be_nil
    end
  end
end
