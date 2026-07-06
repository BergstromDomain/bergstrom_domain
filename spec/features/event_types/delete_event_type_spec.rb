# spec/features/event_types/delete_event_type_spec.rb

require "rails_helper"

RSpec.describe "Delete event type", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in_as(admin) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Deletes an event type with no associated events and redirects to index" do
      et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events.")
      visit event_type_path(et)
      click_button "Delete Event Type"
      expect(page).to have_current_path(event_types_path)
      expect(page).not_to have_content("Wedding")
    end

    it "Removes the event type from the database" do
      et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events.")
      visit event_type_path(et)
      expect {
        click_button "Delete Event Type"
      }.to change(EventType, :count).by(-1)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Does not delete an event type that has associated events" do
      et = create(:event_type, name: "Music", icon: "music", description: "Music events.")
      create(:event, event_type: et)
      visit event_type_path(et)
      expect {
        click_button "Delete Event Type"
      }.not_to change(EventType, :count)
    end

    it "Shows an error when deletion is prevented by associated events" do
      et = create(:event_type, name: "Music", icon: "music", description: "Music events.")
      create(:event, event_type: et)
      visit event_type_path(et)
      click_button "Delete Event Type"
      expect(page).to have_content("Cannot delete record because dependent events exist")
    end

    it "Does not show the 'Delete' button to 'Charlie Content Creator'" do
      et = create(:event_type, name: "Music", icon: "music", description: "Music events.")
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit event_type_path(et)
      expect(page).not_to have_button("Delete Event Type")
    end

    it "Does not show the 'Delete' button to 'Gary Guest'" do
      et = create(:event_type, name: "Music", icon: "music", description: "Music events.")
      click_button "Sign Out"
      visit event_type_path(et)
      expect(page).not_to have_button("Delete Event Type")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Allows 'Sam SysAdmin' to delete an event type" do
      et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events.")
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit event_type_path(et)
      click_button "Delete Event Type"
      expect(page).to have_current_path(event_types_path)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Shows the 'Delete Event Type' button to an 'Adam Admin'" do
      et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events.")
      visit event_type_path(et)
      expect(page).to have_button("Delete Event Type")
    end
  end
end
