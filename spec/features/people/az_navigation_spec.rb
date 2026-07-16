# spec/features/people/az_navigation_spec.rb
require "rails_helper"

RSpec.describe "A-Z Navigation for People", type: :feature do
  let!(:user) { create(:user) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    let!(:james) { create(:person, :james_hetfield, :unrestricted, user: user) }
    let!(:lars)  { create(:person, :lars_ulrich,    :unrestricted, user: user) }

    it "shows an az-nav bar with an All tab active by default" do
      visit people_path
      expect(page).to have_selector("[data-testid='az-nav']")
      expect(page).to have_selector("[data-testid='az-nav-all'].az-nav__link--active")
    end

    it "filters the table to matching people when a letter is selected" do
      visit people_path
      click_link "H"
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Hetfield")
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Lars Ulrich")
    end

    it "clears the filter when All is clicked" do
      visit people_path(letter: "H")
      click_link "All"
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Hetfield")
      expect(page).to have_selector("[data-testid='person-name']", text: "Lars Ulrich")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "renders a letter with no matches as disabled, not a dead link or an error" do
      create(:person, :james_hetfield, :unrestricted, user: user)
      visit people_path
      expect(page).to have_selector("[data-testid='az-nav-link-disabled']", text: "Z")
      expect(page).not_to have_selector("a[data-testid='az-nav-link']", text: "Z")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "leaves the pagination placeholder gone and the table intact" do
      create(:person, :james_hetfield, :unrestricted, user: user)
      visit people_path
      expect(page).not_to have_selector("[data-testid='pagination-placeholder']")
      expect(page).to have_selector("[data-testid='people-table']")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "buckets a person with no last name under their first name's letter" do
      create(:person, :first_name_only, :unrestricted, first_name: "Cliff", user: user)
      visit people_path
      click_link "C"
      expect(page).to have_selector("[data-testid='person-name']", text: "Cliff")
    end
  end
end
