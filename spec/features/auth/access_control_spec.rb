# spec/features/auth/access_control_spec.rb

require "rails_helper"

RSpec.describe "Access control", type: :feature do
  let!(:user)       { create(:user, :content_creator) }
  let!(:admin)      { create(:user, :admin) }
  let!(:event_type) { create(:event_type, name: "Music", description: "Music events", icon: "music") }
  let!(:person)     { create(:person, first_name: "James", last_name: "Hetfield", classification: "unrestricted", user: user) }
  let!(:event) do
    e = create(:event, :unrestricted, title: "Metallica Live", event_type: event_type, user: user)
    e.people << person
    e
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path — public read access" do
    it "allows unauthenticated access to event types index" do
      visit event_types_path
      expect(page.current_path).to eq(event_types_path)
    end

    it "allows unauthenticated access to event type show" do
      visit event_type_path(event_type)
      expect(page.current_path).to eq(event_type_path(event_type))
    end

    it "allows unauthenticated access to events index" do
      visit events_path
      expect(page.current_path).to eq(events_path)
    end

    it "allows unauthenticated access to event show" do
      visit event_path(event)
      expect(page.current_path).to eq(event_path(event))
    end

    it "allows unauthenticated access to people index" do
      visit people_path
      expect(page.current_path).to eq(people_path)
    end

    it "allows unauthenticated access to person show" do
      visit person_path(person)
      expect(page.current_path).to eq(person_path(person))
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path — unauthenticated write access is blocked" do
    it "redirects to sign-in when visiting new event type" do
      visit new_event_type_path
      expect(page.current_path).to eq(new_session_path)
    end

    it "redirects to sign-in when visiting edit event type" do
      visit edit_event_type_path(event_type)
      expect(page.current_path).to eq(new_session_path)
    end

    it "redirects to sign-in when visiting new event" do
      visit new_event_path
      expect(page.current_path).to eq(new_session_path)
    end

    it "redirects to sign-in when visiting edit event" do
      visit edit_event_path(event)
      expect(page.current_path).to eq(new_session_path)
    end

    it "redirects to sign-in when visiting new person" do
      visit new_person_path
      expect(page.current_path).to eq(new_session_path)
    end

    it "redirects to sign-in when visiting edit person" do
      visit edit_person_path(person)
      expect(page.current_path).to eq(new_session_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path — authenticated write access is allowed" do
    it "allows an admin to access new event type" do
      sign_in_as(admin)
      visit new_event_type_path
      expect(page.current_path).to eq(new_event_type_path)
    end

    it "allows an admin to access edit event type" do
      sign_in_as(admin)
      visit edit_event_type_path(event_type)
      expect(page.current_path).to eq(edit_event_type_path(event_type))
    end

    it "allows a content creator to access new event" do
      sign_in_as(user)
      visit new_event_path
      expect(page.current_path).to eq(new_event_path)
    end

    it "allows a content creator to access edit event" do
      sign_in_as(user)
      visit edit_event_path(event)
      expect(page.current_path).to eq(edit_event_path(event))
    end

    it "allows a content creator to access new person" do
      sign_in_as(user)
      visit new_person_path
      expect(page.current_path).to eq(new_person_path)
    end

    it "allows a content creator to access edit person" do
      sign_in_as(user)
      visit edit_person_path(person)
      expect(page.current_path).to eq(edit_person_path(person))
    end

    it "redirects a content creator away from new event type" do
      sign_in_as(user)
      visit new_event_type_path
      expect(page.current_path).to eq(event_types_path)
    end

    it "redirects a content creator away from edit event type" do
      sign_in_as(user)
      visit edit_event_type_path(event_type)
      expect(page.current_path).to eq(event_types_path)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "stores the originally requested URL and redirects after sign-in" do
      visit new_event_path

      fill_in "Email address", with: user.email_address
      fill_in "Password",      with: "password123"
      click_button "Sign in"

      expect(page.current_path).to eq(new_event_path)
    end
  end
end
