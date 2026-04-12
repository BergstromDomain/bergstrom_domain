# spec/features/people/delete_person_spec.rb

require "rails_helper"

RSpec.describe "Delete Person", type: :feature do
  let!(:person) { create(:person, :james_hetfield) }

  it "deletes the person and redirects to the list" do
    visit person_path(person)
    click_button "Delete James Alan Hetfield"

    expect(page).to have_current_path(people_path)
    expect(page).to have_content("Person was successfully deleted.")
    expect(page).not_to have_content("James Alan Hetfield")
  end

  it "reduces the person count by 1" do
    expect {
      visit person_path(person)
      click_button "Delete James Alan Hetfield"
    }.to change(Person, :count).by(-1)
  end
end
