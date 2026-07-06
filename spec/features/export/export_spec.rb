# spec/features/export/export_spec.rb
require "rails_helper"

RSpec.describe "Export", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:uno)     { create(:user) }

  describe "Happy path" do
    it "Allows 'Charlie Content Creator' to download a CSV with default scope" do
      event_type = create(:event_type, name: "Birthday")
      james      = create(:person, user: charlie, first_name: "James", last_name: "Hetfield")
      create(:event, user: charlie, event_type: event_type, title: "James's Birthday").tap do |e|
        e.people << james
      end

      sign_in_as charlie
      visit import_export_path

      click_button "Export"

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.response_headers["Content-Disposition"]).to include("events_export_")
      expect(page.body).to include("James")
      expect(page.body).to include("Hetfield")
      expect(page.body).to include("Birthday")
    end

    it "Includes people with no events as a row with blank event columns" do
      create(:person, user: charlie, first_name: "Kirk", last_name: "Hammett")

      sign_in_as charlie
      visit import_export_path

      click_button "Export"

      expect(page.body).to include("Kirk")
      expect(page.body).to include("Hammett")
    end

    it "Includes multiple events for the same person as separate rows" do
      event_type_birthday    = create(:event_type, name: "Birthday")
      event_type_anniversary = create(:event_type, name: "Anniversary")
      james = create(:person, user: charlie, first_name: "James", last_name: "Hetfield")
      create(:event, user: charlie, event_type: event_type_birthday,    title: "James's Birthday").tap    { |e| e.people << james }
      create(:event, user: charlie, event_type: event_type_anniversary, title: "James's Anniversary").tap { |e| e.people << james }

      sign_in_as charlie
      visit import_export_path

      click_button "Export"

      rows = page.body.split("\n").select { |row| row.include?("James") }
      expect(rows.length).to eq(2)
    end
  end

  describe "Negative path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit import_export_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Shows a disabled export form to 'Uno User'" do
      sign_in_as uno
      visit import_export_path
      expect(page).to have_selector("[data-testid='export-disabled']")
      expect(page).not_to have_button("Export")
    end

    it "Shows a flash error when no scope checkboxes are checked" do
      sign_in_as charlie
      visit import_export_path

      uncheck "My own data"
      uncheck "My contacts"
      click_button "Export"

      expect(page).to have_selector("[data-testid='flash-alert']")
      expect(page).to have_text("at least one")
    end
  end

  describe "Alternative path" do
    it "Exports only public data when only 'Public data' is checked" do
      adam        = create(:user, :admin)
      public_type = create(:event_type, name: "Concert")
      public_person = create(:person, user: adam,
                             first_name: "Robert", last_name: "Trujillo",
                             classification: :unrestricted)
      create(:event, user: adam, event_type: public_type,
             title: "Big Four Tour", classification: :unrestricted).tap do |e|
        e.people << public_person
      end

      sign_in_as charlie
      visit import_export_path

      uncheck "My own data"
      uncheck "My contacts"
      check   "Public data"
      click_button "Export"

      expect(page.response_headers["Content-Type"]).to include("text/csv")
    end
  end

  describe "Edge cases" do
    it "Exports a CSV with only a header row when all scoped data is empty" do
      sign_in_as charlie
      visit import_export_path

      check "My own data"
      click_button "Export"

      lines = page.body.strip.split("\n")
      expect(lines.length).to eq(1)
      expect(lines.first).to include("First name")
    end
  end
end
