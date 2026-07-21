# spec/requests/event_types_mutes_spec.rb
require "rails_helper"

RSpec.describe "EventTypes mute/unmute", type: :request do
  let(:alice) { create(:user) }
  let(:sport) { create(:event_type) }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  # 1) Happy path ───────────────────────────────────────────────────────────
  describe "happy path" do
    it "creates an EventTypeMute for the current user when muting" do
      sign_in(alice)
      expect {
        post mute_event_type_path(sport)
      }.to change { EventTypeMute.where(user: alice, event_type: sport).count }.by(1)
      expect(response).to redirect_to(event_types_path)
    end

    it "destroys the EventTypeMute for the current user when unmuting" do
      create(:event_type_mute, user: alice, event_type: sport)
      sign_in(alice)
      expect {
        delete unmute_event_type_path(sport)
      }.to change { EventTypeMute.where(user: alice, event_type: sport).count }.by(-1)
      expect(response).to redirect_to(event_types_path)
    end
  end

  # 2) Negative path ────────────────────────────────────────────────────────
  describe "negative path" do
    it "redirects an unauthenticated request to mute" do
      post mute_event_type_path(sport)
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects an unauthenticated request to unmute" do
      delete unmute_event_type_path(sport)
      expect(response).to redirect_to(new_session_path)
    end
  end

  # 3) Alternative path ─────────────────────────────────────────────────────
  describe "alternative path" do
    it "does not raise or duplicate a row when muting the same event_type twice" do
      sign_in(alice)
      post mute_event_type_path(sport)
      expect {
        post mute_event_type_path(sport)
      }.not_to change { EventTypeMute.where(user: alice, event_type: sport).count }
    end
  end

  # 4) Edge cases ───────────────────────────────────────────────────────────
  describe "edge cases" do
    it "does not raise when unmuting an event_type that was never muted" do
      sign_in(alice)
      expect {
        delete unmute_event_type_path(sport)
      }.not_to raise_error
      expect(response).to redirect_to(event_types_path)
    end
  end
end
