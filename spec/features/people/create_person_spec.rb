# spec/features/people/create_person_spec.rb
require "rails_helper"

RSpec.describe "Create Person", type: :feature do
  let!(:user) { create(:user, :content_creator) }

  before do |example|
    sign_in_as(user) unless example.metadata[:js]
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates a new person and redirects to their profile" do
      visit new_person_path
      fill_in "First name",  with: "James"
      fill_in "Middle name", with: "Alan"
      fill_in "Last name",   with: "Hetfield"
      fill_in "Description", with: "Vocalist and rhythm guitarist, co-founder of Metallica."
      click_button "Create Person"
      expect(page).to have_css("[data-testid='flash-success']", text: "James Alan Hetfield has been successfully created")
      expect(page).to have_current_path(person_path(Person.last))
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Hetfield")
    end

    xit "Creates a person with an image and displays it on the show page", js: true do
      visit new_person_path
      fill_in "First name", with: "Lars"
      fill_in "Last name",  with: "Ulrich"
      attach_file "Person image", Rails.root.join("spec/fixtures/files/test_image.jpg"),
                  make_visible: true
      click_button "Create Person"
      expect(page).to have_css("[data-testid='flash-success']", text: "Lars Ulrich has been successfully created")
      expect(page).to have_selector("[data-testid='show-panel-main'] img")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows validation errors when first name is missing" do
      visit new_person_path
      click_button "Create Person"
      expect(page).to have_selector("[data-testid='form-errors']")
      expect(page).to have_content("First name can't be blank")
    end

    it "Shows a duplicate name validation error" do
      create(:person, first_name: "James", middle_name: "Alan", last_name: "Hetfield", user: user)
      visit new_person_path
      fill_in "First name",  with: "James"
      fill_in "Middle name", with: "Alan"
      fill_in "Last name",   with: "Hetfield"
      click_button "Create Person"
      expect(page).to have_content("Full name has already been taken")
    end

    it "Redirects an unauthenticated visitor to sign in" do
      click_button "Sign Out"
      visit new_person_path
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Creates a person with only a first name" do
      visit new_person_path
      fill_in "First name", with: "Cliff"
      click_button "Create Person"
      expect(page).to have_css("[data-testid='flash-success']", text: "Cliff has been successfully created")
      expect(page).to have_selector("[data-testid='person-name']", text: "Cliff")
    end

    it "Defaults visibility to Restricted" do
      visit new_person_path
      expect(page).to have_select("Classification", selected: "Restricted — visible only to me")
    end

    it "Defaults visibility to the user's Occasions Settings default" do
      user.app_settings_for("event_tracker").update!(default_classification: "unrestricted")
      visit new_person_path
      expect(page).to have_select("Classification", selected: "Unrestricted — visible to everyone")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows the original heading after a validation failure" do
      visit new_person_path
      click_button "Create Person"
      expect(page).to have_selector("h1.page-title", text: "New Person")
    end
  end
end
