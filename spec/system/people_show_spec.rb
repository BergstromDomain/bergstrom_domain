require "rails_helper"

RSpec.describe "People Show Page", type: :system do
  let!(:person) { create(:person) }

  it "displays the person's details" do
    visit people_path
    click_link person.fullname

    expect(page).to have_content(person.fullname)
    expect(page).to have_content(person.description)
    expect(page).to have_css("img.person-image.full")
    expect(page).to have_link("Back to People", href: people_path)
  end
end