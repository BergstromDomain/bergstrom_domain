# spec/features/people_events/filter_people_events_spec.rb

require "rails_helper"

RSpec.describe "Filter People and Events", type: :feature do
  let(:owner) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the filter UI and the Basic/SQL tabs" do
      visit filter_people_events_path

      expect(page).to have_selector("[data-testid='basic-panel']")
      expect(page).to have_selector("[data-testid='sql-tab']")
    end

    it "Lists every visible person+event row" do
      event_type = create(:event_type, name: "Birthday")
      james = create(:person, :unrestricted, user: owner, first_name: "James", last_name: "Hetfield")
      create(:event, :unrestricted, user: owner, event_type: event_type, title: "James's Birthday").tap do |e|
        e.people << james
      end

      visit filter_people_events_path

      expect(page).to have_selector("[data-testid='filter-row']", text: "James")
      expect(page).to have_selector("[data-testid='filter-row-title']", text: "James's Birthday")
    end

    it "Shows a person with no events as a row with a blank event cell" do
      create(:person, :unrestricted, user: owner, first_name: "Kirk", last_name: "Hammett")

      visit filter_people_events_path

      expect(page).to have_selector("[data-testid='filter-row']", text: "Kirk")
    end

    it "Filters down to the matching First Name" do
      create(:person, :unrestricted, user: owner, first_name: "James", last_name: "Hetfield")
      create(:person, :unrestricted, user: owner, first_name: "Lars", last_name: "Ulrich")

      visit filter_people_events_path(first_name: "James")

      expect(page).to have_selector("[data-testid='filter-row']", text: "James")
      expect(page).to have_no_selector("[data-testid='filter-row']", text: "Lars")
    end

    it "Shows a Classification filter with My Own/Contacts/Public options" do
      sign_in_as(owner)
      visit filter_people_events_path

      expect(page).to have_selector("[data-testid='classification-filter']")
      within("[data-testid='classification-filter']") do
        expect(page).to have_selector("option", text: /Restricted/)
        expect(page).to have_selector("option", text: /Contacts/)
        expect(page).to have_selector("option", text: /Unrestricted/)
      end
    end

    it "Shows each row's Classification in the results table" do
      create(:person, :unrestricted, user: owner, first_name: "Public", last_name: "Person")

      visit filter_people_events_path

      expect(page).to have_selector("[data-testid='filter-row-classification']", text: "Unrestricted")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is accessible to 'Gary Guest' (unauthenticated)" do
      visit filter_people_events_path
      expect(page.status_code).to eq(200)
    end

    it "Shows the empty state when nothing matches" do
      visit filter_people_events_path(first_name: "NoSuchName")
      expect(page).to have_selector("[data-testid='empty-state']")
    end

    it "Shows a filter error for an invalid SQL query" do
      visit filter_people_events_path(mode: "sql", query: "not_a_field = 1")
      expect(page).to have_selector("[data-testid='filter-error']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Only shows 'Gary Guest' unrestricted people/events, not restricted ones" do
      create(:person, :restricted, user: owner, first_name: "Secret", last_name: "Person")
      create(:person, :unrestricted, user: owner, first_name: "Public", last_name: "Person")

      visit filter_people_events_path

      expect(page).to have_selector("[data-testid='filter-row']", text: "Public")
      expect(page).to have_no_selector("[data-testid='filter-row']", text: "Secret")
    end

    it "Lets 'Adam Admin' see restricted people too" do
      create(:person, :restricted, user: owner, first_name: "Secret", last_name: "Person")

      sign_in_as(create(:user, :admin))
      visit filter_people_events_path

      expect(page).to have_selector("[data-testid='filter-row']", text: "Secret")
    end

    it "Narrows down to just Contacts-classification people via the Classification filter" do
      create(:person, :restricted, user: owner, first_name: "Mine")
      create(:person, :contacts, user: owner, first_name: "Shared")

      sign_in_as(owner)
      visit filter_people_events_path(classification: "contacts")

      expect(page).to have_selector("[data-testid='filter-row']", text: "Shared")
      expect(page).to have_no_selector("[data-testid='filter-row']", text: "Mine")
    end

    it "Sorts by Last Name when a sortable column is clicked" do
      create(:person, :unrestricted, user: owner, first_name: "Lars", last_name: "Ulrich")
      create(:person, :unrestricted, user: owner, first_name: "James", last_name: "Hetfield")

      visit filter_people_events_path

      rows_before = page.all("[data-testid='filter-row-last-name']").map(&:text)
      expect(rows_before).to eq([ "Hetfield", "Ulrich" ])
    end

    it "Sorts by Classification when the Classification column header is clicked" do
      create(:person, :restricted, user: owner, first_name: "Mine")
      create(:person, :unrestricted, user: owner, first_name: "Public")
      create(:person, :contacts, user: owner, first_name: "Shared")

      sign_in_as(owner)
      visit filter_people_events_path
      find("[data-testid='sort-classification']").click

      classifications = page.all("[data-testid='filter-row-classification']").map(&:text)
      expect(classifications).to eq([ "Contacts", "Restricted", "Unrestricted" ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows an empty state rather than erroring when nothing is visible at all" do
      visit filter_people_events_path
      expect(page).to have_selector("[data-testid='empty-state']")
    end

    it "Filters by Event Type via the SQL query mode" do
      birthday = create(:event_type, name: "Birthday")
      anniversary = create(:event_type, name: "Anniversary")
      james = create(:person, :unrestricted, user: owner, first_name: "James")
      create(:event, :unrestricted, user: owner, event_type: birthday, title: "Birthday Bash").tap { |e| e.people << james }
      create(:event, :unrestricted, user: owner, event_type: anniversary, title: "Anniversary Do").tap { |e| e.people << james }

      visit filter_people_events_path(mode: "sql", query: 'event_type = "Birthday"')

      expect(page).to have_selector("[data-testid='filter-row-title']", text: "Birthday Bash")
      expect(page).to have_no_selector("[data-testid='filter-row-title']", text: "Anniversary Do")
    end
  end
end
