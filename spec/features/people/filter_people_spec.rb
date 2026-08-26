# spec/features/people/filter_people_spec.rb
require "rails_helper"

RSpec.describe "Filter people", type: :feature do
  let!(:uno) { create(:user, first_name: "Uno", last_name: "User") }

  let!(:public_person) do
    create(:person, :unrestricted, user: uno, first_name: "Public", middle_name: nil, last_name: "Person")
  end

  let!(:contacts_person) do
    create(:person, :contacts, user: uno, first_name: "Contacts", middle_name: nil, last_name: "Person")
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "shows the classification filter only when authenticated" do
      visit people_path
      expect(page).not_to have_selector("[data-testid='classification-nav']")

      sign_in_as uno
      visit people_path
      expect(page).to have_selector("[data-testid='classification-nav']")
    end

    it "filters people by classification" do
      sign_in_as uno
      visit people_path(classification: "contacts")
      expect(page).to have_selector("[data-testid='person-name']", text: "Contacts Person")
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Public Person")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "does not show a classification filter to unauthenticated visitors" do
      visit people_path
      expect(page).not_to have_selector("[data-testid='classification-nav-link']")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "shows everyone again when 'All' is selected" do
      sign_in_as uno
      visit people_path(classification: "contacts")
      within("[data-testid='classification-nav']") { click_link "All" }

      expect(page).to have_selector("[data-testid='person-name']", text: "Public Person")
      expect(page).to have_selector("[data-testid='person-name']", text: "Contacts Person")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "combines the classification filter with the A-Z letter filter" do
      sign_in_as uno
      visit people_path(classification: "unrestricted", letter: "P")
      expect(page).to have_selector("[data-testid='person-name']", text: "Public Person")
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Contacts Person")
    end
  end
end
