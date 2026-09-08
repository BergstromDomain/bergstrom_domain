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
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Hetfield")
    end

    it "displays the description" do
      visit person_path(person)
      expect(page).to have_selector("[data-testid='person-description']",
        text: "Vocalist and rhythm guitarist, co-founder of Metallica.")
    end

    it "displays the main panel" do
      visit person_path(person)
      expect(page).to have_selector("[data-testid='show-panel-main']")
    end

    it "displays the metadata panel" do
      visit person_path(person)
      expect(page).to have_selector("[data-testid='show-panel-metadata']")
    end

    it "displays the actions panel" do
      visit person_path(person)
      expect(page).to have_selector("[data-testid='show-panel-actions']")
    end

    it "is accessible via a friendly URL" do
      visit "/people/james-alan-hetfield"
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Hetfield")
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
      expect(page).to have_selector("[data-testid='edit-link']")
      expect(page).to have_selector("[data-testid='delete-button']")
    end

    it "does not show edit or delete links for a visitor" do
      visit person_path(person)
      expect(page).not_to have_selector("[data-testid='edit-link']")
      expect(page).not_to have_selector("[data-testid='delete-button']")
    end

    it "shows the admin panel to the owner" do
      sign_in_as(user)
      visit person_path(person)
      expect(page).to have_selector("[data-testid='show-panel-admin']")
      expect(page).to have_content(user.email_address)
    end

    it "does not show an Updated By line for a person that has never been edited" do
      sign_in_as(user)
      visit person_path(person)
      expect(page).to have_no_selector("[data-testid='audit-updated']")
    end

    it "shows an Updated By line once the person has been edited" do
      person.update!(updater: user)
      sign_in_as(user)
      visit person_path(person)
      expect(page).to have_selector("[data-testid='audit-updated']", text: user.email_address)
    end

    it "shows events panel when person has events" do
      music = create(:event_type, name: "Music", description: "Music events", icon: "music")
      event = create(:event, :unrestricted, title: "Kill 'Em All",
                     day: 25, month: 7, year: 1983, event_type: music, user: user)
      event.people.clear
      event.people << person
      visit person_path(person)
      expect(page).to have_selector("[data-testid='show-panel-events']")
      expect(page).to have_selector("[data-testid='event-title']", text: "Kill 'Em All")
    end

    it "hides events panel when person has no events" do
      visit person_path(person)
      expect(page).not_to have_selector("[data-testid='show-panel-events']")
    end

    it "shows the social media panel when person has social media accounts" do
      facebook = create(:social_media_platform, name: "Facebook")
      create(:person_social_media_account, person: person, social_media_platform: facebook, username: "jhetfield")
      visit person_path(person)
      expect(page).to have_selector("[data-testid='show-panel-social-media']")
      expect(page).to have_selector("[data-testid='social-media-account-platform']", text: "Facebook")
      expect(page).to have_selector("[data-testid='social-media-account-username']", text: "jhetfield")
    end

    it "hides the social media panel when person has no social media accounts" do
      visit person_path(person)
      expect(page).not_to have_selector("[data-testid='show-panel-social-media']")
    end

    it "links each platform name to its show page" do
      facebook = create(:social_media_platform, name: "Facebook")
      create(:person_social_media_account, person: person, social_media_platform: facebook)
      visit person_path(person)
      expect(page).to have_link("Facebook", href: social_media_platform_path(facebook))
    end

    it "shows a fallback icon when the platform has no logo" do
      facebook = create(:social_media_platform, name: "Facebook")
      create(:person_social_media_account, person: person, social_media_platform: facebook)
      visit person_path(person)
      expect(page).to have_selector("[data-testid='social-media-account-logo'] svg")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "resolves old slug after a name change" do
      person.update!(last_name: "Newsted")
      visit "/people/james-alan-hetfield"
      expect(page).to have_selector("[data-testid='person-name']", text: "James Alan Newsted")
    end
  end
end
