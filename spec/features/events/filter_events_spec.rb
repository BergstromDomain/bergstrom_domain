# spec/features/events/filter_events_spec.rb
require "rails_helper"

RSpec.describe "Filter events", type: :feature do
  let!(:uno)   { create(:user, first_name: "Uno", last_name: "User") }
  let!(:music) { create(:event_type, name: "Music", description: "Musical events", icon: "music") }
  let!(:sport) { create(:event_type, name: "Sport", description: "Sport events",   icon: "trophy") }
  let!(:adam)  { create(:person, user: uno, first_name: "Adam", middle_name: nil, last_name: "Ant") }
  let!(:anna)  { create(:person, user: uno, first_name: "Anna", middle_name: nil, last_name: "Bell") }

  let!(:birthday) do
    e = create(:event, :unrestricted, title: "Adam's Birthday",
               event_type: music, day: 1, month: 1, year: 2020, user: uno)
    e.people = [ adam ]
    e
  end

  let!(:joint_party) do
    e = create(:event, :unrestricted, title: "Joint Party",
               event_type: music, day: 2, month: 1, year: 2020, user: uno)
    e.people = [ adam, anna ]
    e
  end

  let!(:sport_day) do
    e = create(:event, :unrestricted, title: "Sport Day",
               event_type: sport, day: 3, month: 1, year: 2020, user: uno)
    e.people = [ adam ]
    e
  end

  # Owned-by-self "contacts"-classified events are the only non-unrestricted
  # classification that appears in a regular (non-admin) user's own index —
  # Classifiable.visible_to_users never surfaces "restricted" events there,
  # even to their own owner (that's existing, unrelated behavior).
  let!(:contacts_note) do
    e = create(:event, :contacts, title: "Contacts Note",
               event_type: music, day: 4, month: 1, year: 2020, user: uno)
    e.people = [ adam ]
    e
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "shows the classification and mute filter navs only when authenticated" do
      visit events_path
      expect(page).not_to have_selector("[data-testid='classification-nav']")
      expect(page).not_to have_selector("[data-testid='mute-filter-nav']")

      sign_in_as uno
      visit events_path
      expect(page).to have_selector("[data-testid='classification-nav']")
      expect(page).to have_selector("[data-testid='mute-filter-nav']")
    end

    it "filters events by classification" do
      sign_in_as uno
      visit events_path(classification: "contacts")
      expect(page).to have_selector("[data-testid='event-title']", text: "Contacts Note")
      expect(page).not_to have_selector("[data-testid='event-title']", text: "Adam's Birthday")
    end

    it "defaults to hiding events whose only person is muted" do
      create(:person_mute, user: uno, person: adam)
      sign_in_as uno
      visit events_path

      expect(page).not_to have_selector("[data-testid='event-title']", text: "Adam's Birthday")
      expect(page).not_to have_selector("[data-testid='event-title']", text: "Sport Day")
      expect(page).to have_selector("[data-testid='event-title']", text: "Joint Party")
    end

    it "shows everything again when 'Show all' is selected" do
      create(:person_mute, user: uno, person: adam)
      sign_in_as uno
      visit events_path(show_all: true)

      expect(page).to have_selector("[data-testid='event-title']", text: "Adam's Birthday")
      expect(page).to have_selector("[data-testid='event-title']", text: "Sport Day")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "does not show a mute button for unauthenticated visitors" do
      visit events_path
      expect(page).not_to have_selector("[data-testid='event-mute-cell']")
    end
  end

  # 3) Alternative path ─────────────────────────────────────────────────────
  describe "alternative path" do
    it "hides an event that is muted directly, even with an unmuted person on it" do
      create(:event_mute, user: uno, event: joint_party)
      sign_in_as uno
      visit events_path
      expect(page).not_to have_selector("[data-testid='event-title']", text: "Joint Party")
    end

    it "hides every event of a muted event_type" do
      create(:event_type_mute, user: uno, event_type: sport)
      sign_in_as uno
      visit events_path
      expect(page).not_to have_selector("[data-testid='event-title']", text: "Sport Day")
      expect(page).to have_selector("[data-testid='event-title']", text: "Adam's Birthday")
    end

    it "mutes an event from the index row and it disappears after reload" do
      sign_in_as uno
      visit events_path
      find("[data-testid='mute-event-#{birthday.id}']").click
      visit events_path
      expect(page).not_to have_selector("[data-testid='event-title']", text: "Adam's Birthday")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "keeps an event visible if only some of its people are muted" do
      create(:person_mute, user: uno, person: adam)
      sign_in_as uno
      visit events_path
      expect(page).to have_selector("[data-testid='event-title']", text: "Joint Party")
    end

    it "unmuting an event via its index button makes it reappear" do
      create(:event_mute, user: uno, event: birthday)
      sign_in_as uno
      visit events_path
      expect(page).not_to have_selector("[data-testid='event-title']", text: "Adam's Birthday")

      visit events_path(show_all: true)
      find("[data-testid='unmute-event-#{birthday.id}']").click

      visit events_path
      expect(page).to have_selector("[data-testid='event-title']", text: "Adam's Birthday")
    end
  end
end
