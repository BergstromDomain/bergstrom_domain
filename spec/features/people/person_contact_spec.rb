# spec/features/people/person_contact_spec.rb
require "rails_helper"

# A Person's Contact frame: their Work Email, seen by anyone who can see the
# Person (Dossier's Colleagues and Staff are People).
RSpec.describe "Person Contact", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:person)  { create(:person, :unrestricted, user: charlie, first_name: "Anna", last_name: "Andersson") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds a Work Email on Edit and shows it in the Contact frame" do
      sign_in_as(charlie)
      visit edit_person_path(person)
      within("[data-testid='edit-panel-contact']") { fill_in "Work Email", with: "anna@example.com" }
      click_button "Update Person"

      expect(find("[data-testid='show-panel-contact']")).to have_link("anna@example.com", href: "mailto:anna@example.com")
    end

    it "Takes a Work Email when the Person is created" do
      sign_in_as(charlie)
      visit new_person_path
      fill_in "First name", with: "Bertil"
      within("[data-testid='new-panel-contact']") { fill_in "Work Email", with: "bertil@example.com" }
      click_button "Create Person"

      expect(page).to have_css("[data-testid='person-work-email']", text: "bertil@example.com")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Rejects a Work Email that isn't one" do
      sign_in_as(charlie)
      visit edit_person_path(person)
      fill_in "Work Email", with: "anna-at-example"
      click_button "Update Person"

      expect(page).to have_css("[data-testid='field-error']", text: "is invalid")
    end

    it "Won't delete a Person who is a Dossier Colleague, saying why" do
      create(:dossier_colleague, person: person)
      sign_in_as(charlie)
      visit person_path(person)
      click_button "Delete Person"

      expect(page).to have_current_path(person_path(person))
      expect(page).to have_text("Anna Andersson is a Colleague or Staff member in Dossier: remove them there first.")
      expect(Person.exists?(person.id)).to be(true)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows the Work Email to a visitor who can see the Person" do
      person.update!(work_email: "anna@example.com")
      visit person_path(person)

      expect(page).to have_css("[data-testid='person-work-email']", text: "anna@example.com")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Has no Contact frame without a Work Email" do
      visit person_path(person)

      expect(page).not_to have_css("[data-testid='show-panel-contact']")
    end
  end
end
