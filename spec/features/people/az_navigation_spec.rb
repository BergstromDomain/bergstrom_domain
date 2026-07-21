# spec/features/people/az_navigation_spec.rb
require "rails_helper"

RSpec.describe "A-Z Navigation for People", type: :feature do
  let!(:user) { create(:user) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    let!(:james) { create(:person, :james_hetfield, :unrestricted, user: user) }
    let!(:lars)  { create(:person, :lars_ulrich,    :unrestricted, user: user) }

    it "Shows an az-nav bar with an All tab active by default" do
      visit people_path
      expect(page).to have_selector("[data-testid='az-nav']")
      expect(page).to have_selector("[data-testid='az-nav-all'].az-nav__link--active")
    end

    it "Filters the table to matching people when a letter is selected" do
      visit people_path
      click_link "H"
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Hetfield")
      expect(page).not_to have_selector("[data-testid='person-name']", text: "Lars Ulrich")
    end

    it "Clears the filter when All is clicked" do
      visit people_path(letter: "H")
      click_link "All"
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Hetfield")
      expect(page).to have_selector("[data-testid='person-name']", text: "Lars Ulrich")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Renders a letter with no matches as disabled, not a dead link or an error" do
      create(:person, :james_hetfield, :unrestricted, user: user)
      visit people_path
      expect(page).to have_selector("[data-testid='az-nav-link-disabled']", text: "Z")
      expect(page).not_to have_selector("a[data-testid='az-nav-link']", text: "Z")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Leaves the pagination placeholder gone and the table intact" do
      create(:person, :james_hetfield, :unrestricted, user: user)
      visit people_path
      expect(page).not_to have_selector("[data-testid='pagination-placeholder']")
      expect(page).to have_selector("[data-testid='people-table']")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Buckets a person with no last name under their first name's letter" do
      create(:person, :first_name_only, :unrestricted, first_name: "Cliff", user: user)
      visit people_path
      click_link "C"
      expect(page).to have_selector("[data-testid='person-name']", text: "Cliff")
    end
  end

  # 5) Swedish sort order ─────────────────────────────────────────────────────
  describe "Swedish sort order" do
    it "Sorts Å, Ä, Ö in Swedish alphabetical order, not code-point order" do
      create(:person, :orjan_oberg,      :unrestricted, user: user)
      create(:person, :peter_agren,      :unrestricted, user: user)
      create(:person, :astrid_arnstrom,  :unrestricted, user: user)
      create(:person, :james_hetfield,   :unrestricted, user: user)
      visit people_path
      names = page.all("[data-testid='person-name']").map(&:text)
      agren_index    = names.index { |n| n.include?("Ågren") }
      arnstrom_index = names.index { |n| n.include?("Ärnström") }
      oberg_index    = names.index { |n| n.include?("Öberg") }
      expect(agren_index).to be < arnstrom_index
      expect(arnstrom_index).to be < oberg_index
    end

    it "Renders all 29 letters of the Swedish alphabet in order, Å Ä Ö last" do
      visit people_path
      rendered_letters = page.all(
        "[data-testid='az-nav-link'], [data-testid='az-nav-link-disabled']"
      ).map(&:text)
      expect(rendered_letters).to eq(Person::BUCKET_LETTERS)
    end

    it "Sorts Å, Ä, Ö correctly on the unfiltered 'All' view, not just within their own bucket" do
      create(:person, :orjan_oberg,     :unrestricted, user: user)
      create(:person, :peter_agren,     :unrestricted, user: user)
      create(:person, :astrid_arnstrom, :unrestricted, user: user)
      create(:person, :james_hetfield,  :unrestricted, user: user)

      visit people_path
      names = page.all("[data-testid='person-name']").map(&:text)

      hetfield_index = names.index { |n| n.include?("Hetfield") }
      agren_index    = names.index { |n| n.include?("Ågren") }

      expect(hetfield_index).to be < agren_index
    end
  end
end
