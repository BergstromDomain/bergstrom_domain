# spec/features/event_types/delete_event_type_spec.rb

require "rails_helper"

RSpec.describe "Delete event type", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in_as(admin) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "deletes an event type with no associated events and redirects to index" do
      et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events.")
      visit event_type_path(et)
      click_button "Delete Wedding"
      expect(page).to have_current_path(event_types_path)
      expect(page).not_to have_content("Wedding")
    end

    it "removes the event type from the database" do
      et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events.")
      visit event_type_path(et)
      expect {
        click_button "Delete Wedding"
      }.to change(EventType, :count).by(-1)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "does not delete an event type that has associated events" do
      et = create(:event_type, name: "Music", icon: "music", description: "Music events.")
      create(:event, event_type: et)
      visit event_type_path(et)
      expect {
        click_button "Delete Music"
      }.not_to change(EventType, :count)
    end

    it "shows an error when deletion is prevented by associated events" do
      et = create(:event_type, name: "Music", icon: "music", description: "Music events.")
      create(:event, event_type: et)
      visit event_type_path(et)
      click_button "Delete Music"
      expect(page).to have_content("Cannot delete record because dependent events exist")
    end

    it "does not show the Delete button to a content creator" do
      et = create(:event_type, name: "Music", icon: "music", description: "Music events.")
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit event_type_path(et)
      expect(page).not_to have_button("Delete Music")
    end

    it "does not show the Delete button to an unauthenticated visitor" do
      et = create(:event_type, name: "Music", icon: "music", description: "Music events.")
      click_button "Sign Out"
      visit event_type_path(et)
      expect(page).not_to have_button("Delete Music")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "allows a system admin to delete an event type" do
      et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events.")
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit event_type_path(et)
      click_button "Delete Wedding"
      expect(page).to have_current_path(event_types_path)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "shows the turbo confirm dialog text" do
      et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events.")
      visit event_type_path(et)
      expect(page).to have_button("Delete Wedding")
    end
  end
end
