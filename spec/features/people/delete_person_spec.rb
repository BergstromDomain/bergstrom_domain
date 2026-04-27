# spec/features/people/delete_person_spec.rb
require "rails_helper"

RSpec.describe "Delete Person", type: :feature do
  let!(:user)   { create(:user, :content_creator) }
  let!(:person) { create(:person, :james_hetfield, user: user) }

  before { sign_in_as(user) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "deletes the person and redirects to the list" do
      visit person_path(person)
      find("[data-testid='delete-button']").click
      expect(page).to have_current_path(people_path)
      expect(page).to have_content("Person was successfully deleted.")
      expect(page).not_to have_content("James Alan Hetfield")
    end

    it "reduces the person count by 1" do
      expect {
        visit person_path(person)
        find("[data-testid='delete-button']").click
      }.to change(Person, :count).by(-1)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "does not show the delete button to a visitor" do
      click_button "Sign Out"
      visit person_path(person)
      expect(page).not_to have_css("[data-testid='delete-button']")
    end

    it "does not show the delete button to a non-owner" do
      click_button "Sign Out"
      sign_in_as(create(:user))
      visit person_path(person)
      expect(page).not_to have_css("[data-testid='delete-button']")
    end
  end
end
