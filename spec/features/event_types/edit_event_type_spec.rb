# spec/features/event_types/edit_event_type_spec.rb

require "rails_helper"

RSpec.describe "Edit event type", type: :feature do
  let(:admin)      { create(:user, :admin) }
  let!(:event_type) { create(:event_type, name: "Music", icon: "music", description: "Music events.") }

  before { sign_in_as(admin) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Updates the name and regenerates the slug" do
      et = create(:event_type, name: "Fitness", icon: "dumbbell", description: "Fitness events.")
      visit edit_event_type_path(et)
      fill_in "Name", with: "Sport"
      click_button "Update Event Type"
      et.reload
      expect(page).to have_current_path(event_type_path(et))
      expect(page).to have_selector("h1.page-title", text: "Sport")
      expect(et.slug).to eq("sport")
    end

    it "Updates the icon and shows the new icon on the show page" do
      et = create(:event_type, name: "Sport", icon: "dumbbell", description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Icon", with: "trophy"
      click_button "Update Event Type"
      expect(page).to have_selector("[data-testid='event-type-icon'] svg")
      et.reload
      expect(et.icon).to eq("trophy")
    end

    it "Shows the edit form heading with the event type name" do
      visit edit_event_type_path(event_type)
      expect(page).to have_selector("h1.page-title", text: "Music")
    end

    it "Pre-populates the name field" do
      visit edit_event_type_path(event_type)
      expect(page).to have_field("Name", with: "Music")
    end

    it "Pre-populates the icon field" do
      visit edit_event_type_path(event_type)
      expect(page).to have_field("Icon", with: "music")
    end

    it "Shows a preview of the current icon on the edit form" do
      visit edit_event_type_path(event_type)
      expect(page).to have_selector("[data-testid='edit-panel-main'] svg")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Shows an error when updated name is already taken" do
      create(:event_type, name: "Work", icon: "briefcase", description: "Work events.")
      et = create(:event_type, name: "Sport", icon: "trophy", description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Name", with: "Work"
      click_button "Update Event Type"
      expect(page).to have_content("has already been taken")
      et.reload
      expect(et.name).to eq("Sport")
    end

    it "Shows an error when icon is not a valid Lucide icon name" do
      et = create(:event_type, name: "Sport", icon: "trophy", description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Icon", with: "not-a-real-icon"
      click_button "Update Event Type"
      expect(page).to have_content("is not a valid Lucide icon name")
      et.reload
      expect(et.icon).to eq("trophy")
    end

    it "Redirects 'Charlie Content Creator' to the event types index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit edit_event_type_path(event_type)
      expect(page).to have_current_path(event_types_path)
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      click_button "Sign Out"
      visit edit_event_type_path(event_type)
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Old slug resolves to the record after a name change" do
      et = create(:event_type, name: "Fitness", icon: "dumbbell", description: "Fitness events.")
      old_slug = et.slug
      visit edit_event_type_path(et)
      fill_in "Name", with: "Sport"
      click_button "Update Event Type"
      visit event_type_path(old_slug)
      expect(page).to have_selector("h1.page-title", text: "Sport")
    end

    it "Re-renders the form with entered values when validation fails" do
      et = create(:event_type, name: "Sport", icon: "trophy", description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Name", with: ""
      click_button "Update Event Type"
      expect(page).to have_field("Icon", with: "trophy")
    end

    it "Allows 'Sam SysAdmin' to edit an event type" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit edit_event_type_path(event_type)
      fill_in "Name", with: "Live Music"
      click_button "Update Event Type"
      expect(page).to have_selector("h1.page-title", text: "Live Music")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Shows an error when icon has surrounding whitespace" do
      visit edit_event_type_path(event_type)
      fill_in "Icon", with: " music "
      click_button "Update Event Type"
      expect(page).to have_content("is not a valid Lucide icon name")
    end

    it "Preserves the description when only the name is changed" do
      visit edit_event_type_path(event_type)
      fill_in "Name", with: "Live Music"
      click_button "Update Event Type"
      expect(page).to have_selector("[data-testid='event-type-description']",
                               text: "Music events.")
    end
  end
end
