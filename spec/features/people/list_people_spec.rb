require "rails_helper"

RSpec.describe "List People", type: :feature do
  context "when no people exist" do
    it "shows an empty state message" do
      visit people_path
      expect(page).to have_content("No people found")
    end
  end

  context "when people exist" do
    let!(:james)  { create(:person, :james_hetfield) }
    let!(:lars)   { create(:person, :lars_ulrich) }
    let!(:kirk)   { create(:person, :kirk_hammett) }
    let!(:robert) { create(:person, :robert_trujillo) }

    it "displays all people" do
      visit people_path

      expect(page).to have_content("James Alan Hetfield")
      expect(page).to have_content("Lars Ulrich")
      expect(page).to have_content("Kirk Lee Hammett")
      expect(page).to have_content("Robert Agustin Trujillo")
    end

    it "links to each person's profile" do
      visit people_path
      click_link "James Alan Hetfield"
      expect(page).to have_current_path(person_path(james))
    end

    it "shows a link to add a new person" do
      visit people_path
      expect(page).to have_link("Add Person", href: new_person_path)
    end
  end
end
