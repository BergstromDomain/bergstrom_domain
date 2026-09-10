# spec/features/event_types/mute_event_type_spec.rb
require "rails_helper"

RSpec.describe "Mute Event Type", type: :feature do
  let!(:uno)   { create(:user, first_name: "Uno", last_name: "User") }
  let!(:sport) { create(:event_type, name: "Sport", description: "Sport events", icon: "trophy") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Mutes an event_type from the index row" do
      sign_in_as uno
      visit event_types_path

      expect {
        find("[data-testid='mute-event-type-#{sport.id}']").click
      }.to change { EventTypeMute.where(user: uno, event_type: sport).count }.by(1)

      expect(page).to have_css("[data-testid='flash-notice']")
      expect(page).to have_selector("[data-testid='unmute-event-type-#{sport.id}']")
    end

    it "Unmutes an event_type from the index row" do
      create(:event_type_mute, user: uno, event_type: sport)
      sign_in_as uno
      visit event_types_path

      expect {
        find("[data-testid='unmute-event-type-#{sport.id}']").click
      }.to change { EventTypeMute.where(user: uno, event_type: sport).count }.by(-1)

      expect(page).to have_selector("[data-testid='mute-event-type-#{sport.id}']")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Does not show a mute button for unauthenticated visitors" do
      visit event_types_path
      expect(page).not_to have_selector("[data-testid='event-type-mute-cell']")
    end
  end
end
