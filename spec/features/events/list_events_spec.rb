require "rails_helper"

RSpec.describe "List Events", type: :feature do
  context "when no events exist" do
    it "shows an empty state message" do
      visit events_path
      expect(page).to have_content("No events found")
    end
  end

  context "when events exist" do
    let!(:music) { create(:event_type, name: "Music", description: "Musical events", icon: "music") }

    let!(:kill_em_all)    { create(:event, title: "Kill 'Em All",       day: 25, month: 7, year: 1983, event_type: music) }
    let!(:ride_lightning) { create(:event, title: "Ride the Lightning", day: 27, month: 7, year: 1984, event_type: music) }
    let!(:master_puppets) { create(:event, title: "Master of Puppets",  day: 3,  month: 3, year: 1986, event_type: music) }

    it "displays all events" do
      visit events_path
      expect(page).to have_content("Kill 'Em All")
      expect(page).to have_content("Ride the Lightning")
      expect(page).to have_content("Master of Puppets")
    end

    it "links to each event's page" do
      visit events_path
      click_link "Kill 'Em All"
      expect(page).to have_current_path(event_path(kill_em_all))
    end

    it "displays events in chronological order" do
      visit events_path
      expect(page.text.index("Kill 'Em All")).to be < page.text.index("Ride the Lightning")
    end

    it "shows a link to add a new event" do
      visit events_path
      expect(page).to have_link("Add Event", href: new_event_path)
    end
  end
end
