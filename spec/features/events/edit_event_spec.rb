# spec/features/events/edit_event_spec.rb
require "rails_helper"

RSpec.describe "Edit Event", type: :feature do
  let!(:user)     { create(:user) }
  let!(:music)    { create(:event_type, name: "Music",  description: "Musical events", icon: "music") }
  let!(:sport)    { create(:event_type, name: "Sport",  description: "Sporting events", icon: "trophy") }
  let!(:hetfield) { create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield") }
  let!(:ulrich)   { create(:person, first_name: "Lars",  middle_name: nil, last_name: "Ulrich") }
  let!(:event) do
    e = create(:event,
      title:      "Kill 'Em All",
      day:        25,
      month:      7,
      year:       1983,
      event_type: music,
      user:       user
    )
    e.people << hetfield
    e
  end

  before do |example|
    sign_in_as(user) unless example.metadata[:js]
  end

  context "with valid changes" do
    it "updates the event and redirects to its page" do
      visit edit_event_path(event)
      fill_in "Title", with: "Kill 'Em All (Remastered)"
      select "Sport",  from: "Event Type"
      select "Lars Ulrich", from: "People"
      click_button "Update Event"
      event.reload
      expect(page).to have_current_path(event_path(event))
      expect(page).to have_content("Event was successfully updated.")
      expect(page).to have_content("Kill 'Em All (Remastered)")
      expect(page).to have_content("Sport")
      expect(page).to have_content("Lars Ulrich")
    end
  end

  context "uploading an event image", js: true do
    xit "attaches the image and shows it on the show page" do
      sign_in_as(user)
      visit edit_event_path(event)
      attach_file "Event image", Rails.root.join("spec/fixtures/files/test_image.jpg"), make_visible: true
      click_button "Update Event"
      event.reload
      expect(page).to have_current_path(event_path(event))
      expect(page).to have_css("img")
    end
  end

  context "with invalid data" do
    it "shows a validation error" do
      visit edit_event_path(event)
      fill_in "Title", with: ""
      click_button "Update Event"
      expect(page).to have_content("Title can't be blank")
    end
  end
end
