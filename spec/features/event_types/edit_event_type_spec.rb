# spec/features/event_types/edit_event_type_spec.rb
require "rails_helper"

RSpec.describe "Edit event type", type: :feature do
  it "updates name and regenerates slug" do
    et = create(:event_type, name: "Fitness", icon: "dumbbell", description: "Fitness events")

    visit edit_event_type_path(et)
    fill_in "Name", with: "Sport"
    click_button "Update Event type"

    et.reload
    expect(page).to have_current_path(event_type_path(et))
    expect(page).to have_content("Event type updated.")
    expect(page).to have_content("Sport")
    expect(et.slug).to eq("sport")
  end

  it "shows errors on invalid update" do
    create(:event_type, name: "Work",    icon: "briefcase", description: "Work events")
    et = create(:event_type, name: "Sport", icon: "dumbbell",  description: "Sport events")

    visit edit_event_type_path(et)
    fill_in "Name", with: "Work"
    click_button "Update Event type"

    expect(page).to have_content("has already been taken")
  end
end
