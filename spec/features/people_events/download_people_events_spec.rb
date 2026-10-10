# spec/features/people_events/download_people_events_spec.rb

require "rails_helper"

RSpec.describe "Download People and Events", type: :feature do
  let(:owner) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the filter UI and a Download CSV action" do
      sign_in_as(owner)
      visit people_events_exports_path

      expect(page).to have_selector("[data-testid='basic-panel']")
      expect(page).to have_selector("[data-testid='csv-export-link']")
    end

    it "Shows a Classification filter on the Download page too" do
      sign_in_as(owner)
      visit people_events_exports_path

      expect(page).to have_selector("[data-testid='classification-filter']")
    end

    it "Downloads a CSV with the correct content type and matching people/events" do
      event_type = create(:event_type, name: "Birthday")
      james = create(:person, user: owner, first_name: "James", last_name: "Hetfield")
      create(:event, user: owner, event_type: event_type, title: "James's Birthday").tap { |e| e.people << james }

      sign_in_as(owner)
      visit people_events_exports_path
      click_link "Download CSV"

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.response_headers["Content-Disposition"]).to match(/BergstromDomain_Occasions_\d{4}-\d{2}-\d{2}\.csv/)
      expect(page.body).to include("James")
      expect(page.body).to include("Hetfield")
      expect(page.body).to include("Birthday")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit people_events_exports_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies 'Uno User' (app_user role)" do
      sign_in_as(create(:user))
      visit people_events_exports_path

      expect(page).to have_current_path(event_tracker_path)
      expect(page).to have_content("Not authorised")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Only exports people/events matching the applied First Name filter" do
      james = create(:person, user: owner, first_name: "James", last_name: "Hetfield")
      create(:person, user: owner, first_name: "Lars", last_name: "Ulrich")

      sign_in_as(owner)
      visit people_events_exports_path(first_name: "James")
      click_link "Download CSV"

      rows = CSV.parse(page.body, headers: true)
      expect(rows.map { |r| r["First name"] }).to eq([ "James" ])
    end

    it "Lets 'Adam Admin' export restricted people/events too" do
      create(:person, :restricted, user: owner, first_name: "Secret", last_name: "Person")

      sign_in_as(create(:user, :admin))
      visit people_events_exports_path
      click_link "Download CSV"

      expect(page.body).to include("Secret")
    end

    it "Only exports people matching the applied Classification filter" do
      create(:person, :restricted, user: owner, first_name: "Mine")
      create(:person, :contacts, user: owner, first_name: "Shared")

      sign_in_as(owner)
      visit people_events_exports_path(classification: "contacts")
      click_link "Download CSV"

      rows = CSV.parse(page.body, headers: true)
      expect(rows.map { |r| r["First name"] }).to eq([ "Shared" ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Downloads a CSV with just the header row when the filter matches nothing" do
      sign_in_as(owner)
      visit people_events_exports_path(first_name: "NoSuchName")
      click_link "Download CSV"

      rows = CSV.parse(page.body, headers: true)
      expect(rows.length).to eq(0)
    end

    it "Does not include another user's private data" do
      adam         = create(:user, :admin)
      their_person = create(:person, user: adam, first_name: "Dave", last_name: "Mustaine")
      create(:person, user: owner, first_name: "James", last_name: "Hetfield")

      sign_in_as(owner)
      visit people_events_exports_path
      click_link "Download CSV"

      expect(page.body).to include("James")
      expect(page.body).not_to include("Dave")
    end
  end
end
