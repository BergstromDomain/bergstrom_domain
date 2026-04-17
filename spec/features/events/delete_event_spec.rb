# spec/features/events/delete_event_spec.rb
require "rails_helper"

RSpec.describe "Delete Event", type: :feature do
  let!(:user)     { create(:user) }
  let!(:music)    { create(:event_type, name: "Music", description: "Musical events", icon: "music") }
  let!(:hetfield) { create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield") }
  let!(:event) do
    e = create(:event, title: "Load", event_type: music, day: 4, month: 6, year: 1996, user: user)
    e.people << hetfield
    e
  end

  before do
    sign_in_as(user)
  end

  it "deletes the event and redirects to the list" do
    visit event_path(event)
    click_button "Delete Event"
    expect(page).to have_current_path(events_path)
    expect(page).to have_content("Event was successfully deleted.")
    expect(page).not_to have_content("Load")
  end

  it "reduces the event count by 1" do
    expect {
      visit event_path(event)
      click_button "Delete Event"
    }.to change(Event, :count).by(-1)
  end
end
