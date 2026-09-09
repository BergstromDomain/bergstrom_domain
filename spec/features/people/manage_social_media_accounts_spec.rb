# spec/features/people/manage_social_media_accounts_spec.rb

require "rails_helper"

RSpec.describe "Manage social media accounts on a Person", type: :feature do
  let!(:user)     { create(:user, :content_creator) }
  let!(:person)   { create(:person, :james_hetfield, user: user) }
  let!(:facebook) { create(:social_media_platform, name: "Facebook") }
  let!(:instagram) { create(:social_media_platform, name: "Instagram") }

  before do |example|
    sign_in_as(user) unless example.metadata[:js]
  end

  # See spec/features/shared/confirm_dialog_spec.rb for provenance — sign-in
  # under the JS driver is occasionally flaky (cold-boot race), so every
  # js: true example below signs in through this retry wrapper instead of
  # calling sign_in_as directly.
  def sign_in_and_settle(user, attempts: 3)
    attempts.times do
      sign_in_as(user)
      return if page.has_css?("[data-testid='user-thumbnail-dropdown']", wait: 8)
    end
    raise "sign_in_and_settle: could not sign in as #{user.email_address} after #{attempts} attempts"
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Displays an existing account's platform and username pre-filled" do
      create(:person_social_media_account, person: person, social_media_platform: facebook, username: "jhetfield")
      visit edit_person_path(person)
      within("[data-testid='social-media-account-row']") do
        expect(page).to have_select("Platform", selected: "Facebook")
        expect(page).to have_field("Username", with: "jhetfield")
      end
    end

    it "Updates an existing account's username" do
      account = create(:person_social_media_account, person: person, social_media_platform: facebook, username: "old_handle")
      visit edit_person_path(person)
      fill_in "Username", with: "new_handle"
      click_button "Update Person"
      expect(account.reload.username).to eq("new_handle")
    end

    it "Removes an existing account by clicking Remove and submitting" do
      create(:person_social_media_account, person: person, social_media_platform: facebook)
      visit edit_person_path(person)
      find("[data-testid='remove-social-media-account-button']").click
      click_button "Update Person"
      expect(person.reload.person_social_media_accounts).to be_empty
    end

    it "Adds a new social media account via 'Add Social Media Platform'", js: true do
      sign_in_and_settle(user)
      visit edit_person_path(person)
      expect(page).to have_current_path(edit_person_path(person))
      click_button "Add Social Media Platform"
      within all("[data-testid='social-media-account-row']").last do
        select "Facebook", from: "Platform"
        fill_in "Username", with: "jhetfield"
      end
      click_button "Update Person"

      expect(page).to have_current_path(person_path(person))
      expect(person.reload.social_media_platforms).to include(facebook)
      expect(person.person_social_media_accounts.find_by(social_media_platform: facebook).username).to eq("jhetfield")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Shows an error when two accounts share the same platform" do
      create(:person_social_media_account, person: person, social_media_platform: facebook, username: "one")
      create(:person_social_media_account, person: person, social_media_platform: instagram, username: "two")
      visit edit_person_path(person)

      all("[data-testid='social-media-platform-select']")[1].select "Facebook"
      click_button "Update Person"

      expect(page).to have_content("can only include one account per platform")
    end

    it "Shows an error when username is cleared on a row with a platform selected" do
      create(:person_social_media_account, person: person, social_media_platform: facebook, username: "jhetfield")
      visit edit_person_path(person)
      fill_in "Username", with: ""
      click_button "Update Person"
      expect(page).to have_content("can't be blank")
    end

    it "Redirects a signed-out visitor away from the edit page" do
      click_button "Sign Out"
      visit edit_person_path(person)
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Leaves a newly added but never-filled-in row out of the saved accounts", js: true do
      sign_in_and_settle(user)
      visit edit_person_path(person)
      click_button "Add Social Media Platform"
      click_button "Update Person"

      expect(page).to have_current_path(person_path(person))
      expect(person.reload.person_social_media_accounts).to be_empty
    end

    it "Allows removing a freshly-added row before submitting, without it being saved", js: true do
      sign_in_and_settle(user)
      visit edit_person_path(person)
      expect(page).to have_current_path(edit_person_path(person))
      click_button "Add Social Media Platform"
      within all("[data-testid='social-media-account-row']").last do
        select "Facebook", from: "Platform"
        fill_in "Username", with: "jhetfield"
        find("[data-testid='remove-new-social-media-account']").click
      end
      click_button "Update Person"

      expect(page).to have_current_path(person_path(person))
      expect(person.reload.person_social_media_accounts).to be_empty
    end

    it "Hides an existing row immediately when Remove is clicked, before submitting", js: true do
      create(:person_social_media_account, person: person, social_media_platform: facebook)
      sign_in_and_settle(user)
      visit edit_person_path(person)
      expect(page).to have_current_path(edit_person_path(person))

      find("[data-testid='remove-social-media-account-button']").click

      expect(page).to have_no_selector("[data-testid='social-media-account-row']", visible: :visible)
      expect(person.reload.person_social_media_accounts).not_to be_empty
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    # Removing and re-adding the same platform is done as two round-trips
    # (not a single simultaneous submission) — the old row is still
    # physically in the DB at validation time within one submission, which
    # trips the new row's own uniqueness check against its
    # not-yet-actually-destroyed sibling. Realistic two-step usage sidesteps
    # that Rails nested-attributes ordering quirk entirely.
    it "Allows the same platform to be re-added after its previous account was removed", js: true do
      create(:person_social_media_account, person: person, social_media_platform: facebook, username: "old_handle")
      sign_in_and_settle(user)
      visit edit_person_path(person)
      expect(page).to have_current_path(edit_person_path(person))

      find("[data-testid='remove-social-media-account-button']").click
      click_button "Update Person"
      expect(page).to have_current_path(person_path(person))
      expect(person.reload.person_social_media_accounts).to be_empty

      visit edit_person_path(person)
      click_button "Add Social Media Platform"
      within all("[data-testid='social-media-account-row']").last do
        select "Facebook", from: "Platform"
        fill_in "Username", with: "new_handle"
      end
      click_button "Update Person"

      expect(page).to have_current_path(person_path(person))
      person.reload
      expect(person.person_social_media_accounts.count).to eq(1)
      expect(person.person_social_media_accounts.first.username).to eq("new_handle")
    end

    it "Shows each existing account in its own row when a person has several" do
      create(:person_social_media_account, person: person, social_media_platform: facebook, username: "fb_handle")
      create(:person_social_media_account, person: person, social_media_platform: instagram, username: "ig_handle")
      visit edit_person_path(person)
      expect(page).to have_selector("[data-testid='social-media-account-row']", count: 2)
    end

    it "Renders no rows and no error when the person has no social media accounts" do
      visit edit_person_path(person)
      expect(page).to have_no_selector("[data-testid='social-media-account-row']")
      expect(page).to have_button("Add Social Media Platform")
    end
  end
end
