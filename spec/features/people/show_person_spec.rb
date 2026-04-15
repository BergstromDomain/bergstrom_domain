require "rails_helper"

RSpec.describe "Show Person", type: :feature do
  let!(:person) do
    create(:person,
      first_name:   "James",
      middle_name:  "Alan",
      last_name:    "Hetfield",
      description:  "Vocalist and rhythm guitarist, co-founder of Metallica."
    )
  end

  it "displays the person's full name" do
    visit person_path(person)
    expect(page).to have_content("James Alan Hetfield")
  end

  it "displays the description" do
    visit person_path(person)
    expect(page).to have_content("Vocalist and rhythm guitarist, co-founder of Metallica.")
  end

  it "has links to edit and go back to the list" do
    user = create(:user)
    sign_in_as(user)
    visit person_path(person)
    expect(page).to have_link("Edit")
    expect(page).to have_link("Back to People")
  end

  it "is accessible via a friendly URL" do
    visit "/people/james-alan-hetfield"
    expect(page).to have_content("James Alan Hetfield")
  end

  it "returns 404 for a non-existent person" do
    visit person_path(id: 99999)
    expect(page).to have_http_status(:not_found)
  end
end
