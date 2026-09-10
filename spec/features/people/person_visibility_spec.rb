# spec/features/people/person_visibility_spec.rb
require "rails_helper"

RSpec.describe "Person Visibility", type: :feature do
  let!(:owner)              { create(:user, :content_creator) }
  let!(:visitor_person)     { create(:person, :james_hetfield, :unrestricted, user: owner) }
  let!(:contacts_person)    { create(:person, :lars_ulrich,    :contacts,     user: owner) }
  let!(:restricted_person)  { create(:person, :kirk_hammett,   :restricted,   user: owner) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows unrestricted people to unauthenticated visitors" do
      visit people_path
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Hetfield")
    end

    it "Shows unrestricted and contacts people to the owner" do
      sign_in_as(owner)
      visit people_path
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Hetfield")
      expect(page).to have_selector("[data-testid='person-name']", text: "Lars Ulrich")
    end

    it "Shows the owner's own restricted people on their index" do
      sign_in_as(owner)
      visit people_path
      expect(page).to have_selector("[data-testid='person-name']", text: "Kirk Lee Hammett")

      visit people_path(classification: "restricted")
      expect(page).to have_selector("[data-testid='person-name']", text: "Kirk Lee Hammett")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Hides contacts and restricted people from unauthenticated visitors" do
      visit people_path
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Lars Ulrich")
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Kirk Lee Hammett")
    end

    it "Redirects a visitor away from a restricted person's show page" do
      visit person_path(restricted_person)
      expect(page).to have_current_path(people_path)
      expect(page).to have_content("You do not have permission to view that person.")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows unrestricted people to an authenticated app user" do
      sign_in_as(create(:user))
      visit people_path
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Hetfield")
    end

    it "Shows all people to an admin" do
      sign_in_as(create(:user, :admin))
      visit people_path
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Hetfield")
      expect(page).to have_selector("[data-testid='person-name']", text: "Lars Ulrich")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows the classification on the show page" do
      sign_in_as(owner)
      visit person_path(visitor_person)
      expect(page).to have_selector("[data-testid='person-classification']", text: "Unrestricted")
    end
  end
end
