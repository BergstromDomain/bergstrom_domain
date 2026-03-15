require "rails_helper"

RSpec.describe "People index", type: :system do
  it "loads successfully" do
    Person.create!(firstname: "James", lastname: "Hetfield")

    visit "/people"

    expect(page).to have_content("James Hetfield")
  end
end
