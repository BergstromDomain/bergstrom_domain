# spec/features/events/list_events_spec.rb

require "rails_helper"

RSpec.describe "List events", type: :feature do
  let!(:user)     { create(:user) }
  let!(:music)    { create(:event_type, name: "Music",  description: "Musical events", icon: "music") }
  let!(:sport)    { create(:event_type, name: "Sport",  description: "Sport events",   icon: "trophy") }
  let!(:hetfield) { create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield") }
  let!(:ulrich)   { create(:person, first_name: "Lars",  middle_name: nil, last_name: "Ulrich") }

  let!(:master) do
    e = create(:event, :unrestricted, title: "Master of Puppets",
               event_type: music, day: 3, month: 3, year: 1986, user: user)
    e.people.clear
    e.people << hetfield
    e
  end

  let!(:black_album) do
    e = create(:event, :unrestricted, title: "Metallica (Black Album)",
               event_type: music, day: 12, month: 8, year: 1991, user: user)
    e.people.clear
    e.people << hetfield
    e
  end

  let!(:load) do
    e = create(:event, :unrestricted, title: "Load",
               event_type: music, day: 4, month: 6, year: 1996, user: user)
    e.people.clear
    e.people << ulrich
    e
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    before { visit events_path }

    it "displays the page title" do
      expect(page).to have_css("h1.page-title", text: "Events")
    end

    it "displays all events" do
      expect(page).to have_css("[data-testid='event-title']", count: 3)
    end

    it "displays events in month, day, title order" do
      titles = page.all("[data-testid='event-title']").map(&:text)
      expect(titles).to eq([ "Master of Puppets", "Load", "Metallica (Black Album)" ])
    end

    it "links each title to the event show page" do
      expect(page).to have_link("Master of Puppets", href: event_path(master))
    end

    it "displays the date for each event" do
      expect(page).to have_css("[data-testid='event-date']", count: 3)
      expect(page).to have_css("[data-testid='event-date']", text: "3 Mar 1986")
    end

    it "displays the event type icon for each event" do
      expect(page).to have_css("[data-testid='event-type-icon']", count: 3)
    end

    it "shows the event type icon as thumbnail fallback when no thumbnail exists" do
      expect(page).to have_css("[data-testid='event-thumbnail']", count: 3)
    end

    it "displays person icons for each event" do
      expect(page).to have_css("[data-testid='event-person']", minimum: 1)
    end

    it "links each person icon to their show page" do
      expect(page).to have_css(
        "a[href='#{person_path(hetfield)}'][data-testid='event-person']"
      )
    end

    it "shows person name as tooltip on hover" do
      expect(page).to have_css(
        "a[title='James Hetfield'][data-testid='event-person']"
      )
    end

    it "shows the month navigation bar" do
      expect(page).to have_css("[data-testid='month-nav']")
      expect(page).to have_css("[data-testid='month-nav-link']", count: 12)
    end

    it "shows the pagination placeholder" do
      expect(page).to have_css("[data-testid='pagination-placeholder']")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "shows an empty state when no events exist" do
      Event.destroy_all
      visit events_path
      expect(page).to have_css("[data-testid='empty-state']")
      expect(page).to have_content("No events found")
    end

    it "shows an empty state when no events match the selected month" do
      visit events_path(month: 12)
      expect(page).to have_css("[data-testid='empty-state']")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "filters events by month when month param is present" do
      visit events_path(month: 3)
      expect(page).to have_css("[data-testid='event-title']", text: "Master of Puppets")
      expect(page).not_to have_css("[data-testid='event-title']", text: "Load")
    end

    it "highlights the selected month in the navigation" do
      visit events_path(month: 3)
      expect(page).to have_css(".month-nav__link--active", text: "Mar")
    end

    it "highlights All when no month is selected" do
      visit events_path
      expect(page).to have_css(".month-nav__link--active", text: "All")
    end

    it "filters events by event type when event_type_id param is present" do
      sport_event = create(:event, :unrestricted, title: "Sport Event",
                           event_type: sport, day: 1, month: 1, year: 2000, user: user)
      sport_event.people.clear
      sport_event.people << hetfield
      visit events_path(event_type_id: sport.id)
      expect(page).to have_css("[data-testid='event-title']", text: "Sport Event")
      expect(page).not_to have_css("[data-testid='event-title']", text: "Master of Puppets")
    end

    it "sorts filtered month events by day then title" do
      extra = create(:event, :unrestricted, title: "Another March Event",
                     event_type: music, day: 1, month: 3, year: 1990, user: user)
      extra.people.clear
      extra.people << hetfield
      visit events_path(month: 3)
      titles = page.all("[data-testid='event-title']").map(&:text)
      expect(titles).to eq([ "Another March Event", "Master of Puppets" ])
    end

    it "shows a thumbnail image when one is attached" do
      event_with_thumb = create(:event, :unrestricted, :with_thumbnail,
                                title: "Thumbnail Event",
                                event_type: music, day: 1, month: 1, year: 2000, user: user)
      event_with_thumb.people.clear
      event_with_thumb.people << hetfield
      visit events_path
      expect(page).to have_css("img.table-thumbnail")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "ignores an invalid month param" do
      visit events_path(month: 99)
      expect(page).to have_css("[data-testid='event-title']", count: 3)
    end

    it "displays an event with no year using short date format" do
      no_year = create(:event, :unrestricted, title: "Undated Gig",
                       event_type: music, day: 15, month: 6, year: nil, user: user)
      no_year.people.clear
      no_year.people << hetfield
      visit events_path
      expect(page).to have_css("[data-testid='event-date']", text: "15 Jun")
    end

    it "wraps person icons when an event has multiple people" do
      master.people << ulrich
      visit events_path
      person_icons = all("[data-testid='event-row']").first
                       .all("[data-testid='event-person']")
      expect(person_icons.count).to eq(2)
    end
  end
end
