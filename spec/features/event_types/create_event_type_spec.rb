# spec/features/event_types/create_event_type_spec.rb
require "rails_helper"

RSpec.describe "Create event type", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in_as(user)
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "creates an event type with all required fields" do
      visit new_event_type_path
      fill_in "Name",        with: "Education"
      fill_in "Description", with: "School, university, and learning milestones."
      fill_in "Icon",        with: "graduation-cap"
      click_button "Create Event type"

      expect(page).to have_content("Education")
      expect(page).to have_css("svg")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "shows an error when name is missing" do
      visit new_event_type_path
      fill_in "Description", with: "Something."
      fill_in "Icon",        with: "star"
      click_button "Create Event type"

      expect(page).to have_content("can't be blank")
      expect(EventType.count).to eq(0)
    end

    it "shows an error when name is a duplicate (same case)" do
      create(:event_type, name: "Music", icon: "music", description: "Musical events.")
      visit new_event_type_path
      fill_in "Name",        with: "Music"
      fill_in "Description", with: "Another music type."
      fill_in "Icon",        with: "mic"
      click_button "Create Event type"

      expect(page).to have_content("has already been taken")
      expect(EventType.count).to eq(1)
    end

    it "shows an error when name is a duplicate (different case)" do
      create(:event_type, name: "Music", icon: "music", description: "Musical events.")
      visit new_event_type_path
      fill_in "Name",        with: "music"
      fill_in "Description", with: "Another music type."
      fill_in "Icon",        with: "mic"
      click_button "Create Event type"

      expect(page).to have_content("has already been taken")
      expect(EventType.count).to eq(1)
    end

    it "shows an error when description is missing" do
      visit new_event_type_path
      fill_in "Name", with: "Education"
      fill_in "Icon", with: "graduation-cap"
      click_button "Create Event type"

      expect(page).to have_content("can't be blank")
      expect(EventType.count).to eq(0)
    end

    it "shows an error when icon is missing" do
      visit new_event_type_path
      fill_in "Name",        with: "Education"
      fill_in "Description", with: "School, university, and learning milestones."
      click_button "Create Event type"

      expect(page).to have_content("can't be blank")
      expect(EventType.count).to eq(0)
    end

    it "shows an error when icon is not a valid Lucide icon name" do
      visit new_event_type_path
      fill_in "Name",        with: "Education"
      fill_in "Description", with: "School, university, and learning milestones."
      fill_in "Icon",        with: "not-a-real-icon"
      click_button "Create Event type"

      expect(page).to have_content("is not a valid Lucide icon name")
      expect(EventType.count).to eq(0)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "re-renders the form with entered values when validation fails" do
      visit new_event_type_path
      fill_in "Name",        with: "Education"
      fill_in "Description", with: "School, university, and learning milestones."
      fill_in "Icon",        with: "not-a-real-icon"
      click_button "Create Event type"

      expect(page).to have_field("Name", with: "Education")
      expect(page).to have_field("Icon", with: "not-a-real-icon")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "shows an error when icon has surrounding whitespace" do
      visit new_event_type_path
      fill_in "Name",        with: "Education"
      fill_in "Description", with: "School, university, and learning milestones."
      fill_in "Icon",        with: " graduation-cap "
      click_button "Create Event type"

      expect(page).to have_content("is not a valid Lucide icon name")
    end
  end
end
