# spec/requests/event_types_mutes_spec.rb
require "rails_helper"

RSpec.describe "Event Types Mutes", type: :request do
  let(:alice) { create(:user) }
  let(:sport) { create(:event_type) }

  # 1) Happy Path ───────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "creates an EventTypeMute for the current user when muting" do
      sign_in_as(alice)
      expect {
        post mute_event_type_path(sport)
      }.to change { EventTypeMute.where(user: alice, event_type: sport).count }.by(1)
      expect(response).to redirect_to(event_types_path)
    end

    it "destroys the EventTypeMute for the current user when unmuting" do
      create(:event_type_mute, user: alice, event_type: sport)
      sign_in_as(alice)
      expect {
        delete unmute_event_type_path(sport)
      }.to change { EventTypeMute.where(user: alice, event_type: sport).count }.by(-1)
      expect(response).to redirect_to(event_types_path)
    end
  end

  # 2) Negative Path ────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "redirects an unauthenticated request to mute" do
      post mute_event_type_path(sport)
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects an unauthenticated request to unmute" do
      delete unmute_event_type_path(sport)
      expect(response).to redirect_to(new_session_path)
    end
  end

  # 3) Alternative Paths ─────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "does not raise or duplicate a row when muting the same event_type twice" do
      sign_in_as(alice)
      post mute_event_type_path(sport)
      expect {
        post mute_event_type_path(sport)
      }.not_to change { EventTypeMute.where(user: alice, event_type: sport).count }
    end
  end

  # 4) Edge Cases ───────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "does not raise when unmuting an event_type that was never muted" do
      sign_in_as(alice)
      expect {
        delete unmute_event_type_path(sport)
      }.not_to raise_error
      expect(response).to redirect_to(event_types_path)
    end
  end
end
