# spec/features/event_types/edit_event_type_spec.rb

require "rails_helper"

RSpec.describe "Edit event type", type: :feature do
  let(:admin)      { create(:user, :admin) }
  let!(:event_type) { create(:event_type, name: "Music", icon: "music", description: "Music events.") }

  before { sign_in_as(admin) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "updates the name and regenerates the slug" do
      et = create(:event_type, name: "Fitness", icon: "dumbbell", description: "Fitness events.")
      visit edit_event_type_path(et)
      fill_in "Name", with: "Sport"
      click_button "Update Event Type"
      et.reload
      expect(page).to have_current_path(event_type_path(et))
      expect(page).to have_css("h1.page-title", text: "Sport")
      expect(et.slug).to eq("sport")
    end

    it "updates the icon and shows the new icon on the show page" do
      et = create(:event_type, name: "Sport", icon: "dumbbell", description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Icon", with: "trophy"
      click_button "Update Event Type"
      expect(page).to have_css("[data-testid='event-type-icon'] svg")
      et.reload
      expect(et.icon).to eq("trophy")
    end

    it "shows the edit form heading with the event type name" do
      visit edit_event_type_path(event_type)
      expect(page).to have_css("h1.page-title", text: "Music")
    end

    it "pre-populates the name field" do
      visit edit_event_type_path(event_type)
      expect(page).to have_field("Name", with: "Music")
    end

    it "pre-populates the icon field" do
      visit edit_event_type_path(event_type)
      expect(page).to have_field("Icon", with: "music")
    end

    it "shows a preview of the current icon on the edit form" do
      visit edit_event_type_path(event_type)
      expect(page).to have_css("[data-testid='edit-panel-main'] svg")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "shows an error when updated name is already taken" do
      create(:event_type, name: "Work", icon: "briefcase", description: "Work events.")
      et = create(:event_type, name: "Sport", icon: "trophy", description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Name", with: "Work"
      click_button "Update Event Type"
      expect(page).to have_content("has already been taken")
      et.reload
      expect(et.name).to eq("Sport")
    end

    it "shows an error when icon is not a valid Lucide icon name" do
      et = create(:event_type, name: "Sport", icon: "trophy", description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Icon", with: "not-a-real-icon"
      click_button "Update Event Type"
      expect(page).to have_content("is not a valid Lucide icon name")
      et.reload
      expect(et.icon).to eq("trophy")
    end

    it "redirects a content creator to the event types index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit edit_event_type_path(event_type)
      expect(page).to have_current_path(event_types_path)
    end

    it "redirects an unauthenticated visitor to sign in" do
      click_button "Sign Out"
      visit edit_event_type_path(event_type)
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "old slug resolves to the record after a name change" do
      et = create(:event_type, name: "Fitness", icon: "dumbbell", description: "Fitness events.")
      old_slug = et.slug
      visit edit_event_type_path(et)
      fill_in "Name", with: "Sport"
      click_button "Update Event Type"
      visit event_type_path(old_slug)
      expect(page).to have_css("h1.page-title", text: "Sport")
    end

    it "re-renders the form with entered values when validation fails" do
      et = create(:event_type, name: "Sport", icon: "trophy", description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Name", with: ""
      click_button "Update Event Type"
      expect(page).to have_field("Icon", with: "trophy")
    end

    it "allows a system admin to edit an event type" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit edit_event_type_path(event_type)
      fill_in "Name", with: "Live Music"
      click_button "Update Event Type"
      expect(page).to have_css("h1.page-title", text: "Live Music")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "shows an error when icon has surrounding whitespace" do
      visit edit_event_type_path(event_type)
      fill_in "Icon", with: " music "
      click_button "Update Event Type"
      expect(page).to have_content("is not a valid Lucide icon name")
    end

    it "preserves the description when only the name is changed" do
      visit edit_event_type_path(event_type)
      fill_in "Name", with: "Live Music"
      click_button "Update Event Type"
      expect(page).to have_css("[data-testid='event-type-description']",
                               text: "Music events.")
    end
  end
end
