# spec/features/event_types/delete_event_type_spec.rb
require "rails_helper"

RSpec.describe "Delete event type", type: :feature do
  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "deletes an event type with no associated events and redirects to index" do
      et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events.")
      visit event_type_path(et)
      click_button "Delete Event Type"

      expect(page).to have_current_path(event_types_path)
      expect(page).not_to have_content("Wedding")
    end

    it "removes the event type from the database" do
      et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events.")
      visit event_type_path(et)
      expect {
        click_button "Delete Event Type"
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
        click_button "Delete Event Type"
      }.not_to change(EventType, :count)
    end

    it "shows an error when deletion is prevented by associated events" do
      et = create(:event_type, name: "Music", icon: "music", description: "Music events.")
      create(:event, event_type: et)
      visit event_type_path(et)
      click_button "Delete Event Type"

      expect(page).to have_content("Cannot delete record because dependent events exist")
    end
  end
end
