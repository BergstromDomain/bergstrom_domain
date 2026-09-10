# spec/features/events/delete_event_spec.rb
require "rails_helper"

RSpec.describe "Delete Event", type: :feature do
  let!(:user) { create(:user, :content_creator) }
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

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Deletes the event and redirects to the list" do
      visit event_path(event)
      click_button "Delete Event"
      expect(page).to have_current_path(events_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Load has been successfully deleted")
      expect(page).to have_no_css("[data-testid='events-table']", text: "Load")
    end

    it "Reduces the event count by 1" do
      expect {
        visit event_path(event)
        click_button "Delete Event"
      }.to change(Event, :count).by(-1)
    end
  end
end
