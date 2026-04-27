# spec/features/people/show_person_spec.rb
require "rails_helper"

RSpec.describe "Show Person", type: :feature do
  let!(:user) { create(:user, :content_creator) }
  let!(:person) do
    create(:person,
      first_name:     "James",
      middle_name:    "Alan",
      last_name:      "Hetfield",
      description:    "Vocalist and rhythm guitarist, co-founder of Metallica.",
      classification: "unrestricted",
      user:           user
    )
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "displays the person's full name" do
      visit person_path(person)
      expect(page).to have_css("[data-testid='person-name']", text: "James Alan Hetfield")
    end

    it "displays the description" do
      visit person_path(person)
      expect(page).to have_css("[data-testid='person-description']",
        text: "Vocalist and rhythm guitarist, co-founder of Metallica.")
    end

    it "displays the main panel" do
      visit person_path(person)
      expect(page).to have_css("[data-testid='show-panel-main']")
    end

    it "displays the metadata panel" do
      visit person_path(person)
      expect(page).to have_css("[data-testid='show-panel-metadata']")
    end

    it "displays the actions panel" do
      visit person_path(person)
      expect(page).to have_css("[data-testid='show-panel-actions']")
    end

    it "is accessible via a friendly URL" do
      visit "/people/james-alan-hetfield"
      expect(page).to have_css("[data-testid='person-name']", text: "James Alan Hetfield")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "returns 404 for a non-existent person" do
      visit person_path(id: "nobody-here")
      expect(page).to have_http_status(:not_found)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "shows edit and delete links for the owner" do
      sign_in_as(user)
      visit person_path(person)
      expect(page).to have_css("[data-testid='edit-link']")
      expect(page).to have_css("[data-testid='delete-button']")
    end

    it "does not show edit or delete links for a visitor" do
      visit person_path(person)
      expect(page).not_to have_css("[data-testid='edit-link']")
      expect(page).not_to have_css("[data-testid='delete-button']")
    end

    it "shows the admin panel to the owner" do
      sign_in_as(user)
      visit person_path(person)
      expect(page).to have_css("[data-testid='show-panel-admin']")
      expect(page).to have_content(user.email_address)
    end

    it "shows events panel when person has events" do
      music = create(:event_type, name: "Music", description: "Music events", icon: "music")
      event = create(:event, :unrestricted, title: "Kill 'Em All",
                     day: 25, month: 7, year: 1983, event_type: music, user: user)
      event.people.clear
      event.people << person
      visit person_path(person)
      expect(page).to have_css("[data-testid='show-panel-events']")
      expect(page).to have_css("[data-testid='event-title']", text: "Kill 'Em All")
    end

    it "hides events panel when person has no events" do
      visit person_path(person)
      expect(page).not_to have_css("[data-testid='show-panel-events']")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "resolves old slug after a name change" do
      person.update!(last_name: "Newsted")
      visit "/people/james-alan-hetfield"
      expect(page).to have_css("[data-testid='person-name']", text: "James Alan Newsted")
    end
  end
end
