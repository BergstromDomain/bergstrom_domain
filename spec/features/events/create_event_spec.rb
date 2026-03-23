require "rails_helper"

RSpec.describe "Create Event", type: :feature do
  context "with valid attributes" do
    it "creates a new event and redirects to its page" do
      visit new_event_path

      fill_in "Title",       with: "Kill 'Em All"
      fill_in "Description", with: "Metallica's debut studio album."
      fill_in "Day",         with: "25"
      fill_in "Month",       with: "7"
      fill_in "Year",        with: "1983"
      click_button "Save Event"

      expect(page).to have_current_path(event_path(Event.last))
      expect(page).to have_content("Kill 'Em All")
      expect(page).to have_content("Event was successfully created.")
    end
  end

  context "without a year" do
    it "is still valid" do
      visit new_event_path

      fill_in "Title", with: "Annual Tour"
      fill_in "Day",   with: "1"
      fill_in "Month", with: "6"
      click_button "Save Event"

      expect(page).to have_content("Annual Tour")
      expect(page).to have_content("Event was successfully created.")
    end
  end

  context "with a missing title" do
    it "shows a validation error" do
      visit new_event_path

      fill_in "Day",   with: "1"
      fill_in "Month", with: "1"
      click_button "Save Event"

      expect(page).to have_content("Title can't be blank")
    end
  end

  context "with a missing day" do
    it "shows a validation error" do
      visit new_event_path

      fill_in "Title", with: "Orphaned Event"
      fill_in "Month", with: "6"
      click_button "Save Event"

      expect(page).to have_content("Day can't be blank")
    end
  end

  context "with a duplicate title" do
    before { create(:event, title: "Kill 'Em All", day: 25, month: 7, year: 1983) }

    it "shows a uniqueness error" do
      visit new_event_path

      fill_in "Title", with: "Kill 'Em All"
      fill_in "Day",   with: "1"
      fill_in "Month", with: "1"
      click_button "Save Event"

      expect(page).to have_content("Title has already been taken")
    end
  end
end
