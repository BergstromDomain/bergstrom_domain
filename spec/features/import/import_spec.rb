# spec/features/import/import_spec.rb
require "rails_helper"

RSpec.describe "Import", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:uno)     { create(:user) }

  describe "Happy path" do
    it "Imports all rows from a valid CSV and shows a success summary" do
      create(:event_type, name: "Birthday")

      sign_in_as charlie
      visit import_export_path

      attach_file "import-file-input", Rails.root.join("spec/fixtures/files/imports/valid_import.csv")
      click_button "Import"

      expect(page).to have_selector("[data-testid='import-results']")
      expect(page).to have_text("2 rows imported")
      expect(page).to have_text("0 rows failed")
      expect(Person.find_by(first_name: "James", last_name: "Hetfield")).to be_present
      expect(Event.find_by(title: "James's Birthday")).to be_present
    end

    it "Shows both counts when some rows pass and some fail" do
      create(:event_type, name: "Birthday")

      sign_in_as charlie
      visit import_export_path

      attach_file "import-file-input", Rails.root.join("spec/fixtures/files/imports/partial_success.csv")
      click_button "Import"

      expect(page).to have_text("1 row imported")
      expect(page).to have_text("1 row failed")
    end

    it "Adds the event to an existing person instead of creating a duplicate" do
      create(:event_type, name: "Birthday")
      create(:person, user: charlie, first_name: "James", last_name: "Hetfield")

      sign_in_as charlie
      visit import_export_path

      attach_file "import-file-input", Rails.root.join("spec/fixtures/files/imports/valid_import.csv")
      click_button "Import"

      expect(Person.where(first_name: "James", last_name: "Hetfield").count).to eq(1)
    end

    it "Adds the person to an existing event instead of creating a duplicate event" do
      birthday = create(:event_type, name: "Birthday")
      create(:event, user: charlie, event_type: birthday, title: "James's Birthday", day: 3, month: 8, year: 1963)

      sign_in_as charlie
      visit import_export_path

      attach_file "import-file-input", Rails.root.join("spec/fixtures/files/imports/valid_import.csv")
      click_button "Import"

      expect(Event.where(title: "James's Birthday").count).to eq(1)
      expect(Event.find_by(title: "James's Birthday").people.map(&:first_name)).to include("James")
    end
  end

  describe "Negative path" do
    it "Shows an alert when no file is attached" do
      sign_in_as charlie
      visit import_export_path

      click_button "Import"

      expect(page).to have_selector("[data-testid='flash-alert']")
      expect(page).to have_text("Please choose a CSV file")
    end

    it "Rejects a non-CSV file type" do
      sign_in_as charlie
      visit import_export_path

      attach_file "import-file-input", Rails.root.join("spec/fixtures/files/imports/not_a_csv.txt")
      click_button "Import"

      expect(page).to have_selector("[data-testid='flash-alert']")
      expect(page).to have_text("must be a CSV file")
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit import_export_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Shows import disabled to 'Uno User'" do
      sign_in_as uno
      visit import_export_path

      expect(page).to have_selector("[data-testid='import-disabled']")
      expect(page).not_to have_button("Import")
    end
  end

  describe "Alternative path" do
    it "Imports successfully with a blank year (year stored as nil)" do
      create(:event_type, name: "Birthday")

      sign_in_as charlie
      visit import_export_path

      attach_file "import-file-input", Rails.root.join("spec/fixtures/files/imports/blank_year.csv")
      click_button "Import"

      expect(page).to have_text("1 row imported")
      event = Event.find_by(title: "James's Birthday")
      expect(event.year).to be_nil
      expect(event.month).to eq(8)
      expect(event.day).to eq(3)
    end

    it "Shows an unknown event type as a failed row" do
      sign_in_as charlie
      visit import_export_path

      attach_file "import-file-input", Rails.root.join("spec/fixtures/files/imports/unknown_event_type.csv")
      click_button "Import"

      expect(page).to have_text("0 rows imported")
      expect(page).to have_text("1 row failed")
      expect(page).to have_text("MadeUpType")
    end
  end

  describe "Edge cases" do
    it "Shows 0 imported, 0 failed for a headers-only CSV" do
      sign_in_as charlie
      visit import_export_path

      attach_file "import-file-input", Rails.root.join("spec/fixtures/files/imports/headers_only.csv")
      click_button "Import"

      expect(page).to have_text("0 rows imported")
      expect(page).to have_text("0 rows failed")
    end

    it "Imports duplicate rows idempotently" do
      create(:event_type, name: "Birthday")

      sign_in_as charlie
      visit import_export_path

      attach_file "import-file-input", Rails.root.join("spec/fixtures/files/imports/duplicate_rows.csv")
      click_button "Import"

      expect(Person.where(first_name: "James", last_name: "Hetfield").count).to eq(1)
      expect(Event.where(title: "James's Birthday").count).to eq(1)
    end
  end
end
