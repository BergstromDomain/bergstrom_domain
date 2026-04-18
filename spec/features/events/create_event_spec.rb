# spec/features/events/create_event_spec.rb
require "rails_helper"

RSpec.describe "Create Event", type: :feature do
  let!(:user) { create(:user, :content_creator) }
  let!(:music)    { create(:event_type, name: "Music", description: "Musical events", icon: "music") }
  let!(:hetfield) { create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield") }

  before do |example|
    sign_in_as(user) unless example.metadata[:js]
  end

  context "with valid attributes" do
    it "creates a new event and redirects to its page" do
      visit new_event_path

      select "Music",          from: "Event Type"
      select "James Hetfield", from: "People"
      fill_in "Title",       with: "Kill 'Em All"
      fill_in "Description", with: "Metallica's debut studio album."
      fill_in "Day",         with: "25"
      fill_in "Month",       with: "7"
      fill_in "Year",        with: "1983"
      click_button "Create Event"

      expect(page).to have_content("Event was successfully created.")
      expect(page).to have_content("Kill 'Em All")
      expect(page).to have_content("James Hetfield")
      expect(page).to have_current_path(event_path(Event.last))
    end
  end

  context "without an event type" do
    it "shows a validation error" do
      visit new_event_path

      select "James Hetfield", from: "People"
      fill_in "Title",       with: "Kill 'Em All"
      fill_in "Description", with: "Metallica's debut studio album."
      fill_in "Day",         with: "25"
      fill_in "Month",       with: "7"
      fill_in "Year",        with: "1983"
      click_button "Create Event"

      expect(page).to have_content("Event type must exist")
    end
  end

  context "without people" do
    it "shows a validation error" do
      visit new_event_path

      select "Music", from: "Event Type"
      fill_in "Title", with: "Orphan Event"
      fill_in "Day",   with: 1
      fill_in "Month", with: 1
      click_button "Create Event"

      expect(page).to have_content("error")
      expect(page).to have_content("Event must have at least one person")
    end
  end

  context "without a year" do
    it "is still valid" do
      visit new_event_path

      select "Music",          from: "Event Type"
      select "James Hetfield", from: "People"
      fill_in "Title", with: "Annual Tour"
      fill_in "Day",   with: "1"
      fill_in "Month", with: "6"
      click_button "Create Event"

      expect(page).to have_content("Annual Tour")
      expect(page).to have_content("Event was successfully created.")
    end
  end

  context "with a missing title" do
    it "shows a validation error" do
      visit new_event_path

      select "Music",          from: "Event Type"
      select "James Hetfield", from: "People"
      fill_in "Day",   with: "1"
      fill_in "Month", with: "1"
      click_button "Create Event"

      expect(page).to have_content("Title can't be blank")
    end
  end

  context "with a missing day" do
    it "shows a validation error" do
      visit new_event_path

      select "Music",          from: "Event Type"
      select "James Hetfield", from: "People"
      fill_in "Title", with: "Orphaned Event"
      fill_in "Month", with: "6"
      click_button "Create Event"

      expect(page).to have_content("Day can't be blank")
    end
  end

  context "with a duplicate title" do
    before do
      e = create(:event, :unrestricted, title: "Kill 'Em All", day: 25, month: 7, year: 1983,
                event_type: music, user: user)
      e.people << hetfield
    end

    it "shows a uniqueness error" do
      visit new_event_path

      select "Music",          from: "Event Type"
      select "James Hetfield", from: "People"
      fill_in "Title", with: "Kill 'Em All"
      fill_in "Day",   with: "1"
      fill_in "Month", with: "1"
      click_button "Create Event"

      expect(page).to have_content("Title has already been taken")
    end
  end

  context "with an image", js: true do
    # TODO: JS session isolation issue — revisit when front-end post addresses file upload interactions
    xit "creates an event with an image and displays it on the show page" do
      visit new_event_path

      select "Music",          from: "Event Type"
      select "James Hetfield", from: "People"
      fill_in "Title", with: "Black Album Release"
      fill_in "Day",   with: "12"
      fill_in "Month", with: "8"
      fill_in "Year",  with: "1991"
      attach_file "Event image", Rails.root.join("spec/fixtures/files/test_image.jpg")
      click_button "Create Event"

      expect(page).to have_content("Event was successfully created.")
      expect(page).to have_css("img")
    end
  end
end
