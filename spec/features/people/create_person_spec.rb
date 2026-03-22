require "rails_helper"

RSpec.describe "Create Person", type: :feature do
  context "with valid attributes" do
    it "creates a new person and redirects to their profile" do
      visit new_person_path

      fill_in "First name", with: "James"
      fill_in "Middle name", with: "Alan"
      fill_in "Last name", with: "Hetfield"
      fill_in "Description", with: "Vocalist and rhythm guitarist, co-founder of Metallica."
      click_button "Save Person"

      expect(page).to have_current_path(person_path(Person.last))
      expect(page).to have_content("James Alan Hetfield")
      expect(page).to have_content("Person was successfully created.")
    end
  end

  context "with missing first name" do
    it "shows a validation error" do
      visit new_person_path

      fill_in "Last name", with: "Hetfield"
      click_button "Save Person"

      expect(page).to have_content("First name can't be blank")
      expect(page).to have_current_path(people_path) # or new_person_path depending on config
    end
  end

  context "with a duplicate full name" do
    before { create(:person, first_name: "James", middle_name: "Alan", last_name: "Hetfield") }

    it "shows a uniqueness error" do
      visit new_person_path

      fill_in "First name", with: "James"
      fill_in "Middle name", with: "Alan"
      fill_in "Last name", with: "Hetfield"
      click_button "Save Person"

      expect(page).to have_content("Full name has already been taken")
    end
  end
end
