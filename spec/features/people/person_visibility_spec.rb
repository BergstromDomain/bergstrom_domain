# spec/features/people/person_visibility_spec.rb
require "rails_helper"

RSpec.describe "Person visibility", type: :feature do
  let!(:owner)              { create(:user, :content_creator) }
  let!(:visitor_person)     { create(:person, :james_hetfield, :unrestricted, user: owner) }
  let!(:contacts_person)    { create(:person, :lars_ulrich,    :contacts,     user: owner) }
  let!(:restricted_person)  { create(:person, :kirk_hammett,   :restricted,   user: owner) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "shows unrestricted people to unauthenticated visitors" do
      visit people_path
      expect(page).to have_css("[data-testid='person-name']", text: "James Alan Hetfield")
    end

    it "shows unrestricted and contacts people to the owner" do
      sign_in_as(owner)
      visit people_path
      expect(page).to have_css("[data-testid='person-name']", text: "James Alan Hetfield")
      expect(page).to have_css("[data-testid='person-name']", text: "Lars Ulrich")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "hides contacts and restricted people from unauthenticated visitors" do
      visit people_path
      expect(page).not_to have_css("[data-testid='person-name']", text: "Lars Ulrich")
      expect(page).not_to have_css("[data-testid='person-name']", text: "Kirk Lee Hammett")
    end

    it "redirects a visitor away from a restricted person's show page" do
      visit person_path(restricted_person)
      expect(page).to have_current_path(people_path)
      expect(page).to have_content("You do not have permission to view that person.")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "shows unrestricted people to an authenticated app user" do
      sign_in_as(create(:user))
      visit people_path
      expect(page).to have_css("[data-testid='person-name']", text: "James Alan Hetfield")
    end

    it "shows all people to an admin" do
      sign_in_as(create(:user, :admin))
      visit people_path
      expect(page).to have_css("[data-testid='person-name']", text: "James Alan Hetfield")
      expect(page).to have_css("[data-testid='person-name']", text: "Lars Ulrich")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "shows the classification on the show page" do
      sign_in_as(owner)
      visit person_path(visitor_person)
      expect(page).to have_css("[data-testid='person-classification']", text: "Unrestricted")
    end
  end
end
