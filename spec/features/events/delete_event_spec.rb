require "rails_helper"

RSpec.describe "Delete Event", type: :feature do
  let!(:event) { create(:event, title: "Kill 'Em All", day: 25, month: 7, year: 1983) }

  it "deletes the event and redirects to the list" do
    visit event_path(event)
    click_button "Delete Event"

    expect(page).to have_current_path(events_path)
    expect(page).to have_content("Event was successfully deleted.")
    expect(page).not_to have_content("Kill 'Em All")
  end

  it "reduces the event count by 1" do
    expect {
      visit event_path(event)
      click_button "Delete Event"
    }.to change(Event, :count).by(-1)
  end
end
