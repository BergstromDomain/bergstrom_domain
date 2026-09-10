# spec/features/events/edit_event_spec.rb
require "rails_helper"

RSpec.describe "Edit Event", type: :feature do
  let!(:user)     { create(:user, :content_creator) }
  let!(:music)    { create(:event_type, name: "Music",  description: "Musical events", icon: "music") }
  let!(:sport)    { create(:event_type, name: "Sport",  description: "Sporting events", icon: "trophy") }
  let!(:hetfield) { create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield") }
  let!(:ulrich)   { create(:person, first_name: "Lars",  middle_name: nil, last_name: "Ulrich") }
  let!(:event) do
    e = create(:event,
      :unrestricted,
      title:      "Kill 'Em All",
      day:        25,
      month:      7,
      year:       1983,
      event_type: music,
      user:       user)
    e.people.clear
    e.people << hetfield
    e
  end

  before { sign_in_as(user) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Displays the original title in the page heading" do
      visit edit_event_path(event)
      expect(page).to have_selector("h1.page-title", text: "Kill 'Em All")
    end

    it "Pre-populates the title field" do
      visit edit_event_path(event)
      expect(page).to have_field("Title", with: "Kill 'Em All")
    end

    it "Updates the title and redirects to the show page" do
      visit edit_event_path(event)
      fill_in "Title", with: "Kill 'Em All (Remastered)"
      click_button "Update Event"
      event.reload
      expect(page).to have_current_path(event_path(event))
      expect(page).to have_css("[data-testid='flash-success']", text: "Kill 'Em All (Remastered) has been successfully updated")
      expect(page).to have_css("[data-testid='flash-info']", text: "Kill 'Em All has been updated to Kill 'Em All (Remastered)")
      expect(page).to have_selector("h1.page-title", text: "Kill 'Em All (Remastered)")
    end

    it "Updates the event type" do
      visit edit_event_path(event)
      select "Sport", from: "Event Type"
      click_button "Update Event"
      event.reload
      expect(event.event_type).to eq(sport)
    end

    it "Displays current people" do
      visit edit_event_path(event)
      expect(page).to have_selector("[data-testid='event-people']", text: "James Hetfield")
    end

    it "Shows the admin panel with creator information" do
      visit edit_event_path(event)
      expect(page).to have_selector("[data-testid='edit-panel-admin']", text: user.email_address)
    end

    it "Records the current user as the updater" do
      visit edit_event_path(event)
      fill_in "Title", with: "Kill 'Em All (Remastered)"
      click_button "Update Event"
      expect(event.reload.updater).to eq(user)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows a validation error when title is cleared" do
      visit edit_event_path(event)
      fill_in "Title", with: ""
      click_button "Update Event"
      expect(page).to have_selector("[data-testid='field-error']")
      expect(page).to have_content("can't be blank")
    end

    it "Redirects an unauthenticated visitor to sign in" do
      click_button "Sign Out"
      visit edit_event_path(event)
      expect(page).to have_current_path(new_session_path)
    end

    it "Redirects a non-owner to the event show page" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit edit_event_path(event)
      expect(page).to have_current_path(event_path(event))
    end
  end

  # 3) Alternative Paths ──────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Preserves existing people when updating other fields" do
      visit edit_event_path(event)
      fill_in "Title", with: "Kill 'Em All (Remastered)"
      click_button "Update Event"
      event.reload
      expect(event.people).to include(hetfield)
    end

    it "Allows updating the visibility" do
      visit edit_event_path(event)
      select "Restricted — visible only to me", from: "Classification"
      click_button "Update Event"
      event.reload
      expect(event.classification).to eq("restricted")
    end

    it "Allows an admin to edit any event, and records the admin as the updater rather than the original owner" do
      click_button "Sign Out"
      admin = create(:user, :admin)
      sign_in_as admin
      visit edit_event_path(event)
      fill_in "Title", with: "Admin Edit"
      click_button "Update Event"
      expect(page).to have_selector("h1.page-title", text: "Admin Edit")
      expect(event.reload.updater).to eq(admin)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Preserves the slug history when title changes" do
      old_slug = event.slug
      visit edit_event_path(event)
      fill_in "Title", with: "Kill 'Em All (Remastered)"
      click_button "Update Event"
      visit event_path(old_slug)
      expect(page).to have_selector("h1.page-title", text: "Kill 'Em All (Remastered)")
    end

    xit "Attaches the image and shows it on the show page", js: true do
      visit edit_event_path(event)
      attach_file "Event image", Rails.root.join("spec/fixtures/files/test_image.jpg"),
                  make_visible: true
      click_button "Update Event"
      event.reload
      expect(page).to have_current_path(event_path(event))
      expect(page).to have_selector("img")
    end
  end
end
