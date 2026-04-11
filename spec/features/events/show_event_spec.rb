require "rails_helper"

RSpec.describe "Show Event", type: :feature do
  let!(:music) { create(:event_type, name: "Music", description: "Musical events", icon: "music") }
  let!(:hetfield) { create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield") }

  let!(:event) do
    e = create(:event,
      title:       "Kill 'Em All",
      description: "Metallica's debut studio album.",
      day:         25,
      month:       7,
      year:        1983,
      event_type:  music
    )
    e.people << hetfield
    e
  end

  it "displays the event title" do
    visit event_path(event)
    expect(page).to have_content("Kill 'Em All")
  end

  it "displays the description" do
    visit event_path(event)
    expect(page).to have_content("Metallica's debut studio album.")
  end

  it "displays the formatted date" do
    visit event_path(event)
    expect(page).to have_content("25 Jul 1983")
  end

  it "displays the people" do
    visit event_path(event)
    expect(page).to have_content("James Hetfield")
  end

  it "is accessible via a friendly URL" do
    visit "/events/kill-em-all"
    expect(page).to have_content("Kill 'Em All")
  end

  it "has links to edit and go back to the list" do
    visit event_path(event)
    expect(page).to have_link("Edit")
    expect(page).to have_link("Back to Events")
  end

  it "returns 404 for a non-existent event" do
    visit event_path(id: "does-not-exist")
    expect(page).to have_http_status(:not_found)
  end

  context "when the event has no year" do
    let!(:undated_event) do
      create(:event, title: "Annual Concert", day: 15, month: 8, year: nil, event_type: music)
    end

    it "displays just the day and month" do
      visit event_path(undated_event)
      expect(page).to have_content("15 Aug")
      expect(page).not_to have_content("15 Aug nil")
    end
  end
end
