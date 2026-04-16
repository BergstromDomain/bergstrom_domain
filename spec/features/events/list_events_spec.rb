require "rails_helper"

RSpec.describe "List Events", type: :feature do
  context "when no events exist" do
    it "shows an empty state message" do
      visit events_path
      expect(page).to have_content("No events found")
    end
  end

  context "when events exist" do
    let!(:music)    { create(:event_type, name: "Music", description: "Musical events", icon: "music") }
    let!(:hetfield) { create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield") }

    let!(:black_album) do
      event = create(:event, title: "Metallica (Black Album)", event_type: music,
                    day: 12, month: 8, year: 1991)
      event.people << hetfield
      event
    end

    let!(:master_of_puppets) do
      event = create(:event, title: "Master of Puppets", event_type: music,
                    day: 3, month: 3, year: 1986)
      event.people << hetfield
      event
    end

    it "displays all events" do
      visit events_path
      expect(page).to have_content("Metallica (Black Album)")
      expect(page).to have_content("Master of Puppets")
    end

    it "links to each event's page" do
      visit events_path
      click_link "Master of Puppets"
      expect(page).to have_current_path(event_path(master_of_puppets))
    end

    it "displays events in chronological order" do
      visit events_path
      master_index = page.text.index("Master of Puppets")
      black_index  = page.text.index("Metallica (Black Album)")
      expect(master_index).to be < black_index
    end

    it "shows a link to add a new event" do
      user = create(:user)
      sign_in_as(user)
      visit events_path
      expect(page).to have_link("Add Event", href: new_event_path)
    end
  end

  context "when an event has a thumbnail image" do
    it "displays the thumbnail" do
      event_type = create(:event_type, name: "Music", description: "Musical events", icon: "music")
      person     = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
      event      = create(:event, :with_thumbnail, title: "Thumbnail Event",
                                                  day: 1, month: 1, year: 2000,
                                                  event_type: event_type)
      event.people << person

      visit events_path

      expect(page).to have_css("img")
    end
  end
end
