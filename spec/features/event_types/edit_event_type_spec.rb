# spec/features/event_types/edit_event_type_spec.rb
require "rails_helper"

RSpec.describe "Edit event type", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in_as(user)
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "updates the name and regenerates the slug" do
      et = create(:event_type, name: "Fitness", icon: "dumbbell", description: "Fitness events.")
      visit edit_event_type_path(et)
      fill_in "Name", with: "Sport"
      click_button "Update Event type"
      et.reload

      expect(page).to have_current_path(event_type_path(et))
      expect(page).to have_content("Sport")
      expect(et.slug).to eq("sport")
    end

    it "updates the icon and shows the new icon on the show page" do
      et = create(:event_type, name: "Sport", icon: "dumbbell", description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Icon", with: "trophy"
      click_button "Update Event type"

      expect(page).to have_css("svg")
      et.reload
      expect(et.icon).to eq("trophy")
    end

    it "shows a static preview of the current icon on the edit form" do
      et = create(:event_type, name: "Music", icon: "music", description: "Music events.")
      visit edit_event_type_path(et)

      expect(page).to have_css("svg")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "shows an error when updated name is already taken" do
      create(:event_type, name: "Work",  icon: "briefcase", description: "Work events.")
      et = create(:event_type, name: "Sport", icon: "trophy",    description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Name", with: "Work"
      click_button "Update Event type"

      expect(page).to have_content("has already been taken")
      et.reload
      expect(et.name).to eq("Sport")
    end

    it "shows an error when icon is not a valid Lucide icon name" do
      et = create(:event_type, name: "Sport", icon: "trophy", description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Icon", with: "not-a-real-icon"
      click_button "Update Event type"

      expect(page).to have_content("is not a valid Lucide icon name")
      et.reload
      expect(et.icon).to eq("trophy")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "old slug resolves to the record after a name change" do
      et = create(:event_type, name: "Fitness", icon: "dumbbell", description: "Fitness events.")
      old_slug = et.slug
      visit edit_event_type_path(et)
      fill_in "Name", with: "Sport"
      click_button "Update Event type"

      visit event_type_path(old_slug)
      expect(page).to have_content("Sport")
    end

    it "re-renders the form with entered values when validation fails" do
      et = create(:event_type, name: "Sport", icon: "trophy", description: "Sport events.")
      visit edit_event_type_path(et)
      fill_in "Name", with: ""
      click_button "Update Event type"

      expect(page).to have_field("Icon", with: "trophy")
    end
  end
end
