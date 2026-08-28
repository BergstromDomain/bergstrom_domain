# spec/requests/events_mutes_spec.rb
require "rails_helper"

RSpec.describe "Events mute/unmute", type: :request do
  let(:alice)   { create(:user) }
  let(:wedding) { create(:event, user: alice) }

  # 1) Happy path ───────────────────────────────────────────────────────────
  describe "happy path" do
    it "creates an EventMute for the current user when muting" do
      sign_in_as(alice)
      expect {
        post mute_event_path(wedding)
      }.to change { EventMute.where(user: alice, event: wedding).count }.by(1)
      expect(response).to redirect_to(events_path)
    end

    it "destroys the EventMute for the current user when unmuting" do
      create(:event_mute, user: alice, event: wedding)
      sign_in_as(alice)
      expect {
        delete unmute_event_path(wedding)
      }.to change { EventMute.where(user: alice, event: wedding).count }.by(-1)
      expect(response).to redirect_to(events_path)
    end
  end

  # 2) Negative path ────────────────────────────────────────────────────────
  describe "negative path" do
    it "redirects an unauthenticated request to mute" do
      post mute_event_path(wedding)
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects an unauthenticated request to unmute" do
      delete unmute_event_path(wedding)
      expect(response).to redirect_to(new_session_path)
    end
  end

  # 3) Alternative path ─────────────────────────────────────────────────────
  describe "alternative path" do
    it "does not raise or duplicate a row when muting the same event twice" do
      sign_in_as(alice)
      post mute_event_path(wedding)
      expect {
        post mute_event_path(wedding)
      }.not_to change { EventMute.where(user: alice, event: wedding).count }
    end
  end

  # 4) Edge cases ───────────────────────────────────────────────────────────
  describe "edge cases" do
    it "does not raise when unmuting an event that was never muted" do
      sign_in_as(alice)
      expect {
        delete unmute_event_path(wedding)
      }.not_to raise_error
      expect(response).to redirect_to(events_path)
    end
  end
end
