# spec/features/event_types/delete_event_type_spec.rb
require "rails_helper"

RSpec.describe "Delete event type", type: :feature do
  it "deletes an event type and redirects to index" do
    et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events")

    visit event_type_path(et)
    click_button "Delete Event Type"

    expect(page).to have_current_path(event_types_path)
    expect(page).to have_content("Event type deleted.")
    expect(page).not_to have_content("Wedding")
  end
end
