# spec/features/people/person_authorization_spec.rb
require "rails_helper"

RSpec.describe "Person authorization", type: :feature do
  let!(:owner)  { create(:user, :content_creator) }
  let!(:other)  { create(:user, :content_creator) }
  let!(:admin)  { create(:user, :admin) }
  let!(:person) { create(:person, :james_hetfield, :unrestricted, user: owner) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "allows a content creator to visit the new person page" do
      sign_in_as(owner)
      visit new_person_path
      expect(page).to have_css("h1.page-title", text: "New Person")
    end

    it "allows the owner to edit their person" do
      sign_in_as(owner)
      visit edit_person_path(person)
      expect(page).to have_css("h1.page-title", text: "James Alan Hetfield")
    end

    it "allows an admin to edit any person" do
      sign_in_as(admin)
      visit edit_person_path(person)
      expect(page).to have_css("h1.page-title", text: "James Alan Hetfield")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "redirects a visitor away from new person" do
      visit new_person_path
      expect(page).to have_current_path(new_session_path)
    end

    it "redirects a non-owner away from edit" do
      sign_in_as(other)
      visit edit_person_path(person)
      expect(page).to have_current_path(person_path(person))
      expect(page).to have_content("You do not have permission to modify that person.")
    end

    it "does not show the delete button to a non-owner" do
      sign_in_as(other)
      visit person_path(person)
      expect(page).not_to have_css("[data-testid='delete-button']")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "allows an app user to view an unrestricted person" do
      sign_in_as(create(:user))
      visit person_path(person)
      expect(page).to have_css("[data-testid='person-name']", text: "James Alan Hetfield")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "redirects to sign in when an unauthenticated user attempts to delete" do
      page.driver.submit :delete, person_path(person), {}
      expect(page).to have_current_path(new_session_path)
    end
  end
end
