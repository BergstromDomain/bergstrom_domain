# spec/features/event_types/list_event_types_spec.rb
require "rails_helper"

RSpec.describe "List event types", type: :feature do
  it "displays all event types ordered by name" do
    create(:event_type, name: "Work",     icon: "briefcase",  description: "Work events")
    create(:event_type, name: "Birthday", icon: "cake",       description: "Birthday events")
    create(:event_type, name: "Sport",    icon: "dumbbell",   description: "Sport events")

    visit event_types_path

    expect(page).to have_content("Birthday")
    expect(page).to have_content("Sport")
    expect(page).to have_content("Work")

    positions = [ "Birthday", "Sport", "Work" ].map { |n| page.text.index(n) }
    expect(positions).to eq(positions.sort)
  end
end
