require "rails_helper"

RSpec.describe "Edit Event", type: :feature do
  let!(:music) { create(:event_type, name: "Music", description: "Musical events", icon: "music") }
  let!(:sport) { create(:event_type, name: "Sport", description: "Sporting events", icon: "trophy") }

  let!(:event) do
    create(:event,
      title:      "Kill 'Em All",
      day:        25,
      month:      7,
      year:       1983,
      event_type: music
    )
  end

  context "with valid changes" do
    it "updates the event and redirects to its page" do
      visit edit_event_path(event)
      fill_in "Title", with: "Kill 'Em All (Remastered)"
      select "Sport",  from: "Event Type"
      click_button "Update Event"
      event.reload
      expect(page).to have_current_path(event_path(event))
      expect(page).to have_content("Event was successfully updated.")
      expect(page).to have_content("Kill 'Em All (Remastered)")
      expect(page).to have_content("Sport")
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
