# spec/features/events/event_authorization_spec.rb
require "rails_helper"

RSpec.describe "Event write authorization", type: :feature do
  let!(:owner)      { create(:user, :content_creator) }
  let!(:other_user) { create(:user) }
  let!(:admin_user) { create(:user, :admin) }
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

    it "allows a system_admin to edit even with a revoke override in place" do
      sys_admin = create(:user, :system_admin)
      create(:app_permission, user: sys_admin, app_name: "event_tracker",
             can_update: false, can_delete: false)
      sign_in_as(sys_admin)
      visit event_path(event)
      expect(page).to have_link("Edit")
      click_on "Edit"
      expect(page).to have_current_path(edit_event_path(event))
    end

    it "allows an app_user with a granted delete override to delete any event" do
      create(:app_permission, user: other_user, app_name: "event_tracker", can_delete: true)
      sign_in_as(other_user)
      visit event_path(event)
      expect(page).to have_button("Delete Event")
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

    it "blocks an admin with a revoked delete override from deleting" do
      create(:app_permission, user: admin_user, app_name: "event_tracker", can_delete: false)
      sign_in_as(admin_user)
      page.driver.submit :delete, event_path(event), {}
      expect(page).to have_current_path(event_path(event))
      expect(page).to have_content("You do not have permission to delete that event.")
    end

    it "blocks a content_creator with a revoked create override from creating" do
      create(:app_permission, user: owner, app_name: "event_tracker", can_create: false)
      sign_in_as(owner)
      visit new_event_path
      select "Music",          from: "Event Type"
      select "James Hetfield", from: "People"
      fill_in "Title", with: "Damage Inc"
      fill_in "Day",   with: "1"
      fill_in "Month", with: "9"
      select "Unrestricted",   from: "Classification"
      click_button "Create Event"
      expect(page).to have_content("You do not have permission to create events.")
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

    it "shows a delete button to an app_user with a granted delete override" do
      create(:app_permission, user: other_user, app_name: "event_tracker", can_delete: true)
      sign_in_as(other_user)
      visit event_path(event)
      expect(page).to have_button("Delete Event")
    end

    it "shows an edit link to an app_user with a granted update override" do
      create(:app_permission, user: other_user, app_name: "event_tracker", can_update: true)
      sign_in_as(other_user)
      visit event_path(event)
      expect(page).to have_link("Edit")
    end
  end

  # 4) Edge cases ───────────────────────────────────────────────────────────
  describe "edge cases" do
    it "redirects an unauthenticated user trying to edit" do
      visit edit_event_path(event)
      expect(page).to have_current_path(new_session_path)
    end

    it "allows a system_admin to create even with a revoked create override" do
      sys_admin = create(:user, :system_admin)
      create(:app_permission, user: sys_admin, app_name: "event_tracker", can_create: false)
      sign_in_as(sys_admin)
      visit new_event_path
      select "Music",          from: "Event Type"
      select "James Hetfield", from: "People"
      fill_in "Title", with: "Orion"
      fill_in "Day",   with: "1"
      fill_in "Month", with: "10"
      select "Unrestricted",   from: "Classification"
      click_button "Create Event"
      expect(page).to have_content("Event was successfully created.")
    end
  end
end
