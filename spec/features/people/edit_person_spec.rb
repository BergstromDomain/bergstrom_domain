# spec/features/people/edit_person_spec.rb

require "rails_helper"

RSpec.describe "Edit Person", type: :feature do
  let!(:person) do
    create(:person, first_name: "Robert", middle_name: "Agustin", last_name: "Trujillo")
  end

  it "updates the person's details" do
    visit edit_person_path(person)
    fill_in "Middle name", with: "Miguel"
    fill_in "Description", with: "Bassist of Metallica since 2003."
    click_button "Save Person"

    expect(page).to have_current_path(person_path(person))
    expect(page).to have_content("Robert Miguel Trujillo")
    expect(page).to have_content("Person was successfully updated.")
  end

  it "shows validation errors when first name is removed" do
    visit edit_person_path(person)
    fill_in "First name", with: ""
    click_button "Save Person"

    expect(page).to have_content("First name can't be blank")
  end

  context "when updating would create a duplicate full name" do
    before { create(:person, first_name: "Cliff", middle_name: nil, last_name: "Burton") }

    it "shows a uniqueness error" do
      visit edit_person_path(person)
      fill_in "First name",  with: "Cliff"
      fill_in "Middle name", with: ""
      fill_in "Last name",   with: "Burton"
      click_button "Save Person"

      expect(page).to have_content("Full name has already been taken")
    end
  end
end
