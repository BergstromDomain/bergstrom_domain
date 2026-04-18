# spec/features/events/event_authorization_spec.rb
require "rails_helper"

RSpec.describe "Event write authorization", type: :feature do
  let!(:owner) { create(:user, :content_creator) }
  let!(:other_user) { create(:user) }
  let!(:admin_user) { create(:user, role: "admin") }
  let!(:event_type) { create(:event_type, name: "Music", description: "Musical events", icon: "music") }
  let!(:hetfield)   { create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield") }

  let!(:event) do
    e = create(:event, :unrestricted, title: "Authorization Test Event",
               event_type: event_type, day: 1, month: 1, year: 2000, user: owner)
    e.people << hetfield
    e
  end

  # 1) Happy path ───────────────────────────────────────────────────────────
  describe "happy path" do
    it "allows the owner to edit their event" do
      sign_in_as(owner)
      visit event_path(event)
      click_on "Edit"
      expect(page).to have_current_path(edit_event_path(event))
    end

    it "allows the owner to delete their event" do
      sign_in_as(owner)
      visit event_path(event)
      click_on "Delete Event"
      expect(page).to have_current_path(events_path)
      expect(page).to have_content("Event was successfully deleted")
    end

    it "allows an admin to edit any event" do
      sign_in_as(admin_user)
      visit event_path(event)
      click_on "Edit"
      expect(page).to have_current_path(edit_event_path(event))
    end

    it "allows an admin to delete any event" do
      sign_in_as(admin_user)
      visit event_path(event)
      click_on "Delete Event"
      expect(page).to have_current_path(events_path)
      expect(page).to have_content("Event was successfully deleted")
    end
  end

  # 2) Negative path ────────────────────────────────────────────────────────
  describe "negative path" do
    it "redirects another user trying to edit the event" do
      sign_in_as(other_user)
      visit edit_event_path(event)
      expect(page).to have_current_path(event_path(event))
      expect(page).to have_content("You do not have permission to modify that event")
    end

    it "does not show edit or delete links to a non-owner" do
      sign_in_as(other_user)
      visit event_path(event)
      expect(page).not_to have_link("Edit")
      expect(page).not_to have_button("Delete Event")
    end
  end

  # 3) Alternative path ─────────────────────────────────────────────────────
  describe "alternative path" do
    it "shows edit and delete links to the owner" do
      sign_in_as(owner)
      visit event_path(event)
      expect(page).to have_link("Edit")
      expect(page).to have_button("Delete Event")
    end

    it "shows edit and delete links to an admin" do
      sign_in_as(admin_user)
      visit event_path(event)
      expect(page).to have_link("Edit")
      expect(page).to have_button("Delete Event")
    end
  end

  # 4) Edge cases ───────────────────────────────────────────────────────────
  describe "edge cases" do
    it "redirects an unauthenticated user trying to edit" do
      visit edit_event_path(event)
      expect(page).to have_current_path(new_session_path)
    end
  end
end
