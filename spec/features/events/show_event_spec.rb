# spec/features/events/show_event_spec.rb
require "rails_helper"

RSpec.describe "Show Event", type: :feature do
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

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit event_path(event) }

    it "Displays the event title in the page heading" do
      expect(page).to have_selector("h1.page-title", text: "Kill 'Em All")
    end

    it "Displays the description section" do
      expect(page).to have_selector("h2", text: "Description")
      expect(page).to have_selector("[data-testid='event-description']",
                               text: "Metallica's debut studio album.")
    end

    it "Displays the event date in the metadata panel" do
      expect(page).to have_selector("[data-testid='event-date']", text: "25 Jul 1983")
    end

    it "Displays the event type in the metadata panel" do
      expect(page).to have_selector("[data-testid='event-type']", text: "Music")
    end

    it "Displays the visibility in the metadata panel" do
      expect(page).to have_selector("[data-testid='event-classification']", text: "Unrestricted")
    end

    it "Displays associated people in the metadata panel" do
      expect(page).to have_selector("[data-testid='event-people']")
      expect(page).to have_link("James Hetfield", href: person_path(hetfield))
    end

    it "Shows the admin panel with creator information" do
      expect(page).to have_selector("[data-testid='show-panel-admin']")
      expect(page).to have_selector("[data-testid='show-panel-admin']",
                               text: user.email_address)
    end

    it "Does not show an Updated By line for an event that has never been edited" do
      expect(page).to have_no_selector("[data-testid='audit-updated']")
    end

    it "Shows an Updated By line once the event has been edited" do
      event.update!(updater: user)
      visit event_path(event)
      expect(page).to have_selector("[data-testid='audit-updated']", text: user.email_address)
    end

    it "Shows a Back to Events button" do
      expect(page).to have_link("Back to Events", href: events_path)
    end

    it "Does not show Edit or Delete to an unauthenticated visitor" do
      expect(page).not_to have_link("Edit Event")
      expect(page).not_to have_button("Delete Event")
    end

    it "Is accessible via a friendly URL" do
      visit "/events/kill-em-all"
      expect(page).to have_selector("h1.page-title", text: "Kill 'Em All")
    end

    it "Returns 404 for a non-existent event" do
      visit event_path(id: "does-not-exist")
      expect(page).to have_http_status(:not_found)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Does not show Edit or Delete to a non-owner" do
      sign_in_as create(:user)
      visit event_path(event)
      expect(page).not_to have_link("Edit Event")
      expect(page).not_to have_button("Delete Event")
    end

    it "Does not show the description section when event has none" do
      no_desc = create(:event, :unrestricted, title: "No Description",
                      event_type: music, day: 1, month: 1, year: 2000,
                      user: user, description: nil)
      no_desc.people << hetfield
      visit event_path(no_desc)
      expect(page).not_to have_selector("[data-testid='event-description']")
      expect(page).not_to have_selector("h2", text: "Description")
    end
  end

  # 3) Alternative Paths ──────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows Edit and Delete to the event owner" do
      sign_in_as user
      visit event_path(event)
      expect(page).to have_link("Edit Event", href: edit_event_path(event))
      expect(page).to have_button("Delete Event")
    end

    it "Displays multiple people as a comma-separated list" do
      event.people << ulrich
      visit event_path(event)
      expect(page).to have_selector("[data-testid='event-people']",
                               text: "James Hetfield")
      expect(page).to have_selector("[data-testid='event-people']",
                               text: "Lars Ulrich")
    end

    it "Links the event type name to the event type show page" do
      visit event_path(event)
      expect(page).to have_link("Music", href: event_type_path(music))
    end

    it "Uses singular Person label for a single attendee" do
      visit event_path(event)
      expect(page).to have_selector(".show-meta-cell__label", text: "Person")
    end

    it "Uses plural People label for multiple attendees" do
      event.people << ulrich
      visit event_path(event)
      expect(page).to have_selector(".show-meta-cell__label", text: "People")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Displays just day and month when year is absent" do
      no_year = create(:event, :unrestricted, title: "Annual Concert",
                       event_type: music, day: 15, month: 8, year: nil, user: user)
      no_year.people << hetfield
      visit event_path(no_year)
      expect(page).to have_selector("[data-testid='event-date']", text: "15 Aug")
      expect(page).not_to have_content("15 Aug nil")
    end

    it "Shows Edit and Delete to an admin for any event" do
      sign_in_as create(:user, :admin)
      visit event_path(event)
      expect(page).to have_link("Edit Event")
      expect(page).to have_button("Delete Event")
    end
  end
end
