# spec/features/people/edit_person_spec.rb
require "rails_helper"

RSpec.describe "Edit Person", type: :feature do
  let!(:user)   { create(:user, :content_creator) }
  let!(:person) { create(:person, :robert_trujillo, :unrestricted, user: user) }

  before do |example|
    sign_in_as(user) unless example.metadata[:js]
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "displays the original full name in the page heading" do
      visit edit_person_path(person)
      expect(page).to have_css("h1.page-title", text: "Robert Agustin Trujillo")
    end

    it "pre-populates the first name field" do
      visit edit_person_path(person)
      expect(page).to have_field("First name", with: "Robert")
    end

    it "updates the person's details and redirects to the show page" do
      visit edit_person_path(person)
      fill_in "Middle name",  with: "Miguel"
      fill_in "Description",  with: "Bassist of Metallica since 2003."
      click_button "Update Person"
      person.reload
      expect(page).to have_current_path(person_path(person))
      expect(page).to have_content("Person was successfully updated.")
      expect(page).to have_css("[data-testid='person-name']", text: "Robert Miguel Trujillo")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "shows validation errors when first name is removed" do
      visit edit_person_path(person)
      fill_in "First name", with: ""
      click_button "Update Person"
      expect(page).to have_css("[data-testid='form-errors']")
      expect(page).to have_content("First name can't be blank")
    end

    it "redirects an unauthenticated visitor to sign in" do
      click_button "Sign Out"
      visit edit_person_path(person)
      expect(page).to have_current_path(new_session_path)
    end

    it "redirects a non-owner to the person show page" do
      click_button "Sign Out"
      sign_in_as(create(:user, :content_creator))
      visit edit_person_path(person)
      expect(page).to have_current_path(person_path(person))
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "shows a uniqueness error when updating to a duplicate full name" do
      create(:person, first_name: "Cliff", middle_name: nil, last_name: "Burton", user: user)
      visit edit_person_path(person)
      fill_in "First name",  with: "Cliff"
      fill_in "Middle name", with: ""
      fill_in "Last name",   with: "Burton"
      click_button "Update Person"
      expect(page).to have_content("Full name has already been taken")
    end

    it "allows an admin to edit any person" do
      click_button "Sign Out"
      sign_in_as(create(:user, :admin))
      visit edit_person_path(person)
      fill_in "First name", with: "Roberto"
      click_button "Update Person"
      expect(page).to have_css("[data-testid='person-name']", text: "Roberto Agustin Trujillo")
    end

    xit "attaches the image and shows it on the show page", js: true do
      sign_in_as(user)
      visit edit_person_path(person)
      expect(page).to have_current_path(edit_person_path(person))
      attach_file "Person image", Rails.root.join("spec/fixtures/files/test_image.jpg")
      click_button "Update Person"
      person.reload
      expect(page).to have_current_path(person_path(person))
      expect(page).to have_css("[data-testid='show-panel-main'] img")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "preserves slug history when name changes" do
      old_slug = person.slug
      visit edit_person_path(person)
      fill_in "Last name", with: "Newsted"
      click_button "Update Person"
      visit person_path(old_slug)
      expect(page).to have_css("[data-testid='person-name']", text: "Robert Agustin Newsted")
    end
  end
end
