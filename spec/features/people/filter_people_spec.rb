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

  let!(:restricted_person) do
    create(:person, :restricted, user: uno, first_name: "Restricted", middle_name: nil, last_name: "Person")
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

    it "filters people by a single checked classification" do
      sign_in_as uno
      visit people_path(classifications: [ "contacts" ])
      expect(page).to have_selector("[data-testid='person-name']", text: "Contacts Person")
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Public Person")
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Restricted Person")
    end

    it "combines two checked classifications at once" do
      sign_in_as uno
      visit people_path(classifications: [ "unrestricted", "restricted" ])
      expect(page).to have_selector("[data-testid='person-name']", text: "Public Person")
      expect(page).to have_selector("[data-testid='person-name']", text: "Restricted Person")
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Contacts Person")
    end

    it "applies the user's saved default classifications on a fresh visit" do
      uno.update!(default_classifications: [ "unrestricted" ])
      sign_in_as uno
      visit people_path
      expect(page).to have_selector("[data-testid='person-name']", text: "Public Person")
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Contacts Person")
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Restricted Person")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "does not show a classification filter to unauthenticated visitors" do
      visit people_path
      expect(page).not_to have_selector("[data-testid='classification-checkbox-restricted']")
    end

    it "shows nothing when every classification is unchecked" do
      sign_in_as uno
      visit people_path(classifications: [ "none" ])
      expect(page).not_to have_selector("[data-testid='person-name']")
      expect(page).to have_selector("[data-testid='empty-state']")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "shows everyone again when all three are checked" do
      sign_in_as uno
      visit people_path(classifications: %w[unrestricted contacts restricted])

      expect(page).to have_selector("[data-testid='person-name']", text: "Public Person")
      expect(page).to have_selector("[data-testid='person-name']", text: "Contacts Person")
      expect(page).to have_selector("[data-testid='person-name']", text: "Restricted Person")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "combines the classification filter with the A-Z letter filter" do
      sign_in_as uno
      visit people_path(classifications: [ "unrestricted" ], letter: "P")
      expect(page).to have_selector("[data-testid='person-name']", text: "Public Person")
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Contacts Person")
    end
  end
end
