# spec/features/people/list_people_spec.rb
require "rails_helper"

RSpec.describe "List People", type: :feature do
  let!(:user) { create(:user) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    context "when people exist" do
      let!(:james)  { create(:person, :james_hetfield,  :unrestricted, user: user) }
      let!(:lars)   { create(:person, :lars_ulrich,     :unrestricted, user: user) }
      let!(:kirk)   { create(:person, :kirk_hammett,    :unrestricted, user: user) }
      let!(:robert) { create(:person, :robert_trujillo, :unrestricted, user: user) }

      it "displays all people" do
        visit people_path
        expect(page).to have_css("[data-testid='people-table']")
        expect(page).to have_css("[data-testid='person-name']", text: "James Alan Hetfield")
        expect(page).to have_css("[data-testid='person-name']", text: "Lars Ulrich")
        expect(page).to have_css("[data-testid='person-name']", text: "Kirk Lee Hammett")
        expect(page).to have_css("[data-testid='person-name']", text: "Robert Agustin Trujillo")
      end

      it "links to each person's profile" do
        visit people_path
        click_link "James Alan Hetfield"
        expect(page).to have_current_path(person_path(james))
      end

      it "shows an Add Person link for content creators" do
        sign_in_as(create(:user, :content_creator))
        visit people_path
        expect(page).to have_css("[data-testid='add-person-link']")
      end

      it "does not show an Add Person link for visitors" do
        visit people_path
        expect(page).not_to have_css("[data-testid='add-person-link']")
      end
    end

    context "when a person has an image" do
      it "displays their thumbnail" do
        create(:person, :with_image, :james_hetfield, :unrestricted, user: user)
        visit people_path
        expect(page).to have_css("[data-testid='person-thumbnail'] img")
      end
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    context "when no people exist" do
      it "shows an empty state message" do
        visit people_path
        expect(page).to have_css("[data-testid='empty-state']")
        expect(page).to have_content("No people found.")
      end
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    context "when a person has no image" do
      it "shows the fallback user icon" do
        create(:person, :james_hetfield, :unrestricted, user: user)
        visit people_path
        expect(page).to have_css("[data-testid='person-thumbnail'] svg")
      end
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "lists people in case-insensitive alphabetical order by last name" do
      create(:person, first_name: "Lars",  last_name: "Ulrich",   classification: "unrestricted", user: user)
      create(:person, first_name: "James", last_name: "Hetfield", classification: "unrestricted", user: user)
      visit people_path
      names = page.all("[data-testid='person-name']").map(&:text)
      expect(names).to eq([ "James Hetfield", "Lars Ulrich" ])
    end
  end
end
