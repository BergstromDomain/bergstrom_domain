# spec/requests/people_mutes_spec.rb
require "rails_helper"

RSpec.describe "People mute/unmute", type: :request do
  let(:alice) { create(:user) }
  let(:adam)  { create(:person, user: alice) }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  # 1) Happy path ───────────────────────────────────────────────────────────
  describe "happy path" do
    it "creates a PersonMute for the current user when muting" do
      sign_in(alice)
      expect {
        post mute_person_path(adam)
      }.to change { PersonMute.where(user: alice, person: adam).count }.by(1)
      expect(response).to redirect_to(people_path)
    end

    it "destroys the PersonMute for the current user when unmuting" do
      create(:person_mute, user: alice, person: adam)
      sign_in(alice)
      expect {
        delete unmute_person_path(adam)
      }.to change { PersonMute.where(user: alice, person: adam).count }.by(-1)
      expect(response).to redirect_to(people_path)
    end
  end

  # 2) Negative path ────────────────────────────────────────────────────────
  describe "negative path" do
    it "redirects an unauthenticated request to mute" do
      post mute_person_path(adam)
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects an unauthenticated request to unmute" do
      delete unmute_person_path(adam)
      expect(response).to redirect_to(new_session_path)
    end
  end

  # 3) Alternative path ─────────────────────────────────────────────────────
  describe "alternative path" do
    it "does not raise or duplicate a row when muting the same person twice" do
      sign_in(alice)
      post mute_person_path(adam)
      expect {
        post mute_person_path(adam)
      }.not_to change { PersonMute.where(user: alice, person: adam).count }
    end
  end

  # 4) Edge cases ───────────────────────────────────────────────────────────
  describe "edge cases" do
    it "does not raise when unmuting a person who was never muted" do
      sign_in(alice)
      expect {
        delete unmute_person_path(adam)
      }.not_to raise_error
      expect(response).to redirect_to(people_path)
    end
  end
end
