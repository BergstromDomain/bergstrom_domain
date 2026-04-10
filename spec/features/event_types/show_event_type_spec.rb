# spec/features/event_types/show_event_type_spec.rb
require "rails_helper"

RSpec.describe "Show event type", type: :feature do
  it "displays the event type details" do
    et = create(:event_type, name: "Music", icon: "music", description: "Musical events and performances")

    visit event_type_path(et)

    expect(page).to have_content("Music")
    expect(page).to have_content("Musical events and performances")
    expect(page).to have_content("music")
  end
end
