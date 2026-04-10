# spec/features/event_types/create_event_type_spec.rb
require "rails_helper"

RSpec.describe "Create event type", type: :feature do
  it "creates an event type via the form", js: true do
    visit new_event_type_path

    fill_in "Name",        with: "Education"
    fill_in "Description", with: "School, university, and learning milestones"

    # Select icon via the picker script
    find(".icon-option[data-icon='graduation-cap']").click

    click_button "Create Event type"

    expect(page).to have_content("Education")
    expect(page).to have_content("Event type created.")
  end

  it "shows errors when name is missing" do
    visit new_event_type_path

    find(".icon-option[data-icon='star']").click
    fill_in "Description", with: "Something"
    click_button "Create Event type"

    expect(page).to have_content("can't be blank")
  end

  it "shows errors when name is a duplicate (case-insensitive)" do
    create(:event_type, name: "Music", icon: "music", description: "Musical events")

    visit new_event_type_path
    fill_in "Name",        with: "music"
    fill_in "Description", with: "Another music type"
    find(".icon-option[data-icon='mic']").click
    click_button "Create Event type"

    expect(page).to have_content("has already been taken")
  end
end
