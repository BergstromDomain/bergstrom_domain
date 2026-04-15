# spec/features/people/create_person_spec.rb
require "rails_helper"

RSpec.describe "Create Person", type: :feature do
  let!(:user)       { create(:user) }

  before do |example|
    sign_in_as(user) unless example.metadata[:js]
  end

  context "with valid attributes" do
    it "creates a new person and redirects to their profile" do
      visit new_person_path
      fill_in "First name", with: "James"
      fill_in "Middle name", with: "Alan"
      fill_in "Last name", with: "Hetfield"
      fill_in "Description", with: "Vocalist and rhythm guitarist, co-founder of Metallica."
      click_button "Save Person"
      expect(page).to have_content("Person was successfully created.")
      expect(page).to have_current_path(person_path(Person.last))
      expect(page).to have_content("James Alan Hetfield")
    end

    # TODO: JS session isolation issue — revisit when front-end post addresses file upload interactions
    xit "creates a person with a thumbnail image", js: true do
      visit new_person_path
      fill_in "First name", with: "Lars"
      fill_in "Last name", with: "Ulrich"
      attach_file "Thumbnail image", Rails.root.join("spec/fixtures/files/test_image.jpg")
      click_button "Save Person"
      expect(page).to have_content("Person was successfully created.")
      expect(page).to have_content("Lars Ulrich")
      expect(page).to have_css("img")
    end
  end

  context "with invalid attributes" do
    it "shows validation errors when first name is missing" do
      visit new_person_path
      click_button "Save Person"
      expect(page).to have_content("First name can't be blank")
    end

    context "when the full name already exists" do
      before { create(:person, first_name: "James", middle_name: "Alan", last_name: "Hetfield") }

      it "shows a duplicate name validation error" do
        visit new_person_path
        fill_in "First name", with: "James"
        fill_in "Middle name", with: "Alan"
        fill_in "Last name", with: "Hetfield"
        click_button "Save Person"
        expect(page).to have_content("Full name has already been taken")
      end
    end
  end
end
