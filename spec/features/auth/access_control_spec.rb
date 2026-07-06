# spec/features/auth/access_control_spec.rb

require "rails_helper"

RSpec.describe "Access control", type: :feature do
  let!(:charlie)       { create(:user, :content_creator) }
  let!(:sam)      { create(:user, :admin) }
  let!(:event_type) { create(:event_type, name: "Music", description: "Music events", icon: "music") }
  let!(:person)     { create(:person, first_name: "James", last_name: "Hetfield", classification: "unrestricted", user: charlie) }
  let!(:event) do
    e = create(:event, :unrestricted, title: "Metallica Live", event_type: event_type, user: charlie)
    e.people << person
    e
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path — public read access" do
    it "Allows 'Gary Guest' access to event types index" do
      visit event_types_path
      expect(page.current_path).to eq(event_types_path)
    end

    it "Allows 'Gary Guest' access to event type show" do
      visit event_type_path(event_type)
      expect(page.current_path).to eq(event_type_path(event_type))
    end

    it "Allows 'Gary Guest' access to events index" do
      visit events_path
      expect(page.current_path).to eq(events_path)
    end

    it "Allows 'Gary Guest' access to event show" do
      visit event_path(event)
      expect(page.current_path).to eq(event_path(event))
    end

    it "Allows 'Gary Guest' access to people index" do
      visit people_path
      expect(page.current_path).to eq(people_path)
    end

    it "Allows 'Gary Guest' access to person show" do
      visit person_path(person)
      expect(page.current_path).to eq(person_path(person))
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path — 'Gary Guest' write access is blocked" do
    it "Redirects to the 'Sign-in' page when 'Gary Guest' visits new event type" do
      visit new_event_type_path
      expect(page.current_path).to eq(new_session_path)
    end

    it "Redirects to the 'Sign-in' page when 'Gary Guest' visits edit event type" do
      visit edit_event_type_path(event_type)
      expect(page.current_path).to eq(new_session_path)
    end

    it "Redirects to the 'Sign-in' page when 'Gary Guest' visits new event" do
      visit new_event_path
      expect(page.current_path).to eq(new_session_path)
    end

    it "Redirects to the 'Sign-in' page when 'Gary Guest' visits edit event" do
      visit edit_event_path(event)
      expect(page.current_path).to eq(new_session_path)
    end

    it "Redirects to the 'Sign-in' page when 'Gary Guest' visits new person" do
      visit new_person_path
      expect(page.current_path).to eq(new_session_path)
    end

    it "Redirects to the 'Sign-in' page when 'Gary Guest' visits edit person" do
      visit edit_person_path(person)
      expect(page.current_path).to eq(new_session_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path — Authenticated write access is allowed" do
    it "Allows 'Adam Admin' to access new event type" do
      sign_in_as(sam)
      visit new_event_type_path
      expect(page.current_path).to eq(new_event_type_path)
    end

    it "Allows 'Adam Admin' to access edit event type" do
      sign_in_as(sam)
      visit edit_event_type_path(event_type)
      expect(page.current_path).to eq(edit_event_type_path(event_type))
    end

    it "Allows 'Charlie Content Creator' to access new event" do
      sign_in_as(charlie)
      visit new_event_path
      expect(page.current_path).to eq(new_event_path)
    end

    it "Allows 'Charlie Content Creator' to access edit event" do
      sign_in_as(charlie)
      visit edit_event_path(event)
      expect(page.current_path).to eq(edit_event_path(event))
    end

    it "Allows 'Charlie Content Creator' to access new person" do
      sign_in_as(charlie)
      visit new_person_path
      expect(page.current_path).to eq(new_person_path)
    end

    it "Allows 'Charlie Content Creator' to access edit person" do
      sign_in_as(charlie)
      visit edit_person_path(person)
      expect(page.current_path).to eq(edit_person_path(person))
    end

    it "Redirects 'Charlie Content Creator' away from new event type" do
      sign_in_as(charlie)
      visit new_event_type_path
      expect(page.current_path).to eq(event_types_path)
    end

    it "Redirects 'Charlie Content Creator' away from edit event type" do
      sign_in_as(charlie)
      visit edit_event_type_path(event_type)
      expect(page.current_path).to eq(event_types_path)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Stores the originally requested URL and redirects 'Charlie Content Creator' after sign-in" do
      visit new_event_path

      fill_in "Email address", with: charlie.email_address
      fill_in "Password",      with: "password123"
      click_button "Sign In"

      expect(page.current_path).to eq(new_event_path)
    end
  end
end
