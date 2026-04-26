# spec/features/events/show_event_spec.rb

require "rails_helper"

RSpec.describe "Show event", type: :feature do
  let!(:user)     { create(:user, :content_creator) }
  let!(:music)    { create(:event_type, name: "Music", description: "Musical events", icon: "music") }
  let!(:hetfield) { create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield") }
  let!(:ulrich)   { create(:person, first_name: "Lars",  middle_name: nil, last_name: "Ulrich") }

  let!(:event) do
    e = create(:event,
      :unrestricted,
      title:       "Kill 'Em All",
      description: "Metallica's debut studio album.",
      day:         25,
      month:       7,
      year:        1983,
      event_type:  music,
      user:        user)
    e.people.clear
    e.people << hetfield
    e
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    before { visit event_path(event) }

    it "displays the event title in the page heading" do
      expect(page).to have_css("h1.page-title", text: "Kill 'Em All")
    end

    it "displays the description section" do
      expect(page).to have_css("h2", text: "Description")
      expect(page).to have_css("[data-testid='event-description']",
                               text: "Metallica's debut studio album.")
    end

    it "displays the event date in the metadata panel" do
      expect(page).to have_css("[data-testid='event-date']", text: "25 Jul 1983")
    end

    it "displays the event type in the metadata panel" do
      expect(page).to have_css("[data-testid='event-type']", text: "Music")
    end

    it "displays the visibility in the metadata panel" do
      expect(page).to have_css("[data-testid='event-classification']", text: "Unrestricted")
    end

    it "displays associated people in the metadata panel" do
      expect(page).to have_css("[data-testid='event-people']")
      expect(page).to have_link("James Hetfield", href: person_path(hetfield))
    end

    it "shows the admin panel with creator information" do
      expect(page).to have_css("[data-testid='show-panel-admin']")
      expect(page).to have_css("[data-testid='show-panel-admin']",
                               text: user.email_address)
    end

    it "shows a Back to Events button" do
      expect(page).to have_link("Back to Events", href: events_path)
    end

    it "does not show Edit or Delete to an unauthenticated visitor" do
      expect(page).not_to have_link("Edit Event")
      expect(page).not_to have_button("Delete Event")
    end

    it "is accessible via a friendly URL" do
      visit "/events/kill-em-all"
      expect(page).to have_css("h1.page-title", text: "Kill 'Em All")
    end

    it "returns 404 for a non-existent event" do
      visit event_path(id: "does-not-exist")
      expect(page).to have_http_status(:not_found)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "does not show Edit or Delete to a non-owner" do
      sign_in_as create(:user)
      visit event_path(event)
      expect(page).not_to have_link("Edit Event")
      expect(page).not_to have_button("Delete Event")
    end

    it "does not show the description section when event has none" do
      no_desc = create(:event, :unrestricted, title: "No Description",
                      event_type: music, day: 1, month: 1, year: 2000,
                      user: user, description: nil)
      no_desc.people << hetfield
      visit event_path(no_desc)
      expect(page).not_to have_css("[data-testid='event-description']")
      expect(page).not_to have_css("h2", text: "Description")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "shows Edit and Delete to the event owner" do
      sign_in_as user
      visit event_path(event)
      expect(page).to have_link("Edit Event", href: edit_event_path(event))
      expect(page).to have_button("Delete Event")
    end

    it "displays multiple people as a comma-separated list" do
      event.people << ulrich
      visit event_path(event)
      expect(page).to have_css("[data-testid='event-people']",
                               text: "James Hetfield")
      expect(page).to have_css("[data-testid='event-people']",
                               text: "Lars Ulrich")
    end

    it "links the event type name to the event type show page" do
      visit event_path(event)
      expect(page).to have_link("Music", href: event_type_path(music))
    end

    it "uses singular Person label for a single attendee" do
      visit event_path(event)
      expect(page).to have_css(".show-meta-cell__label", text: "Person")
    end

    it "uses plural People label for multiple attendees" do
      event.people << ulrich
      visit event_path(event)
      expect(page).to have_css(".show-meta-cell__label", text: "People")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "displays just day and month when year is absent" do
      no_year = create(:event, :unrestricted, title: "Annual Concert",
                       event_type: music, day: 15, month: 8, year: nil, user: user)
      no_year.people << hetfield
      visit event_path(no_year)
      expect(page).to have_css("[data-testid='event-date']", text: "15 Aug")
      expect(page).not_to have_content("15 Aug nil")
    end

    it "shows Edit and Delete to an admin for any event" do
      sign_in_as create(:user, :admin)
      visit event_path(event)
      expect(page).to have_link("Edit Event")
      expect(page).to have_button("Delete Event")
    end
  end
end
