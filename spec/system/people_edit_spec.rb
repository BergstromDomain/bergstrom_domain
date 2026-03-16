require "rails_helper"

RSpec.describe "People Edit Page", type: :system do
  let!(:person) { create(:person) }

  it "updates a person's details successfully" do
    visit edit_person_path(person)

    fill_in "Firstname", with: "UpdatedFirst"
    fill_in "Middlename", with: "UpdatedMiddle"
    fill_in "Lastname", with: "UpdatedLast"
    fill_in "Description", with: "Updated description for testing."
    fill_in "Image", with: "test_person.jpg"
    click_button "Update Person"
    expect(page).to have_content("Person was successfully updated.")
    expect(page).to have_content("UpdatedFirst UpdatedMiddle UpdatedLast")
    expect(page).to have_content("Updated description for testing.")
    expect(page).to have_css("img.person-image.full")
  end

  it "shows validation errors if firstname is blank" do
    visit edit_person_path(person)

    fill_in "Firstname", with: ""
    click_button "Update Person"

    expect(page).to have_content("Firstname can't be blank")
  end
end
