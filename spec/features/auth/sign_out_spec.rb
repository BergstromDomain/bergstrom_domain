# spec/features/auth/sign_out_spec.rb
require "rails_helper"

RSpec.describe "Sign out", type: :feature do
  let!(:user) { create(:user, email_address: "bergstrom@example.com", password: "password123", password_confirmation: "password123") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "signs out a signed-in user and redirects to the sign-in page" do
      sign_in_as(user)

      click_button "Sign out"

      expect(page.current_path).to eq(new_session_path)
    end

    it "prevents accessing write actions after signing out" do
      sign_in_as(user)
      click_button "Sign out"

      visit new_event_type_path

      expect(page.current_path).to eq(new_session_path)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "does not expose a sign-out route for unauthenticated users" do
      visit root_path
      expect(page).not_to have_button("Sign out")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "destroys the session record on sign out" do
      sign_in_as(user)
      expect { click_button "Sign out" }.to change(Session, :count).by(-1)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "handles multiple sign-ins and signs out cleanly" do
      sign_in_as(user)
      click_button "Sign out"
      sign_in_as(user)

      expect(page.current_path).to eq(root_path)
    end
  end
end
