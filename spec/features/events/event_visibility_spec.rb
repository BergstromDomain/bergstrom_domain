# spec/features/events/event_visibility_spec.rb
require "rails_helper"

RSpec.describe "Event visibility", type: :feature do
  let!(:creator)    { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:event_type) { create(:event_type, name: "Music", description: "Musical events", icon: "music") }
  let!(:hetfield)   { create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield") }

  let!(:unrestricted_event) do
    e = create(:event, :unrestricted, title: "Public Gig", event_type: event_type,
               day: 1, month: 1, year: 2000, user: creator)
    e.people << hetfield
    e
  end

  let!(:contacts_event) do
    e = create(:event, :contacts, title: "Contacts Gig", event_type: event_type,
               day: 2, month: 2, year: 2000, user: creator)
    e.people << hetfield
    e
  end

  let!(:restricted_event) do
    e = create(:event, :restricted, title: "Private Gig", event_type: event_type,
               day: 3, month: 3, year: 2000, user: creator)
    e.people << hetfield
    e
  end

  # 1) Happy path ───────────────────────────────────────────────────────────
  describe "happy path" do
    it "shows unrestricted events to unauthenticated visitors on index" do
      visit events_path
      expect(page).to have_content("Public Gig")
      expect(page).not_to have_content("Contacts Gig")
      expect(page).not_to have_content("Private Gig")
    end

    it "shows unrestricted and contacts events to a confirmed contact on index" do
      create(:contact, user: creator, contact: other_user, status: "confirmed")
      sign_in_as(other_user)
      visit events_path
      expect(page).to have_content("Public Gig")
      expect(page).to have_content("Contacts Gig")
      expect(page).not_to have_content("Private Gig")
    end

    it "allows a visitor to view an unrestricted event show page" do
      visit event_path(unrestricted_event)
      expect(page).to have_current_path(event_path(unrestricted_event))
      expect(page).to have_content("Public Gig")
    end

    it "allows an authenticated user to view a contacts event show page" do
      sign_in_as(other_user)
      visit event_path(contacts_event)
      expect(page).to have_current_path(event_path(contacts_event))
      expect(page).to have_content("Contacts Gig")
    end

    it "allows an authenticated user to view a restricted event show page" do
      sign_in_as(other_user)
      visit event_path(restricted_event)
      expect(page).to have_current_path(event_path(restricted_event))
      expect(page).to have_content("Private Gig")
    end
  end

  # 2) Negative path ────────────────────────────────────────────────────────
  describe "negative path" do
    it "redirects a visitor away from a contacts event show page" do
      visit event_path(contacts_event)
      expect(page).to have_current_path(events_path)
      expect(page).to have_content("You do not have permission to view that event.")
    end

    it "redirects a visitor away from a restricted event show page" do
      visit event_path(restricted_event)
      expect(page).to have_current_path(events_path)
      expect(page).to have_content("You do not have permission to view that event.")
    end
  end

  # 3) Alternative path ─────────────────────────────────────────────────────
  describe "alternative path" do
    it "shows the classification on the event show page for authenticated users" do
      sign_in_as(other_user)
      visit event_path(contacts_event)
      expect(page).to have_content("Contacts")
    end

    it "shows unrestricted events to visitors even when contacts events also exist" do
      visit events_path
      expect(page).to have_content("Public Gig")
      expect(page).not_to have_content("Contacts Gig")
    end
  end

  # 4) Edge cases ───────────────────────────────────────────────────────────
  describe "edge cases" do
    it "defaults to contacts classification when creating a new event" do
      sign_in_as(creator)
      visit new_event_path
      expect(page).to have_select("Classification", selected: "Contacts — visible to my contacts")
    end

    it "redirects a visitor to index not sign-in when accessing a non-public event" do
      visit event_path(contacts_event)
      expect(page).to have_current_path(events_path)
      expect(page).not_to have_current_path(new_session_path)
    end
  end
end
