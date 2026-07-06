# spec/features/auth/sign_out_spec.rb
require "rails_helper"

RSpec.describe "Sign Out", type: :feature do
  let!(:user) { create(:user, email_address: "bergstrom@example.com", password: "password123", password_confirmation: "password123") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Signs out a signed-in user and redirects to the 'Home' page" do
      sign_in_as(user)

      click_button "Sign Out"

      expect(page.current_path).to eq(root_path)
    end

    it "Prevents accessing write actions after signing out" do
      sign_in_as(user)
      click_button "Sign Out"

      visit new_event_type_path

      expect(page.current_path).to eq(new_session_path)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Does not expose a sign-out route for unauthenticated users" do
      visit root_path
      expect(page).not_to have_button("Sign Out")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Destroys the session record on sign out" do
      sign_in_as(user)
      expect { click_button "Sign Out" }.to change(Session, :count).by(-1)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Handles multiple sign-ins and signs out cleanly" do
      sign_in_as(user)
      click_button "Sign Out"
      sign_in_as(user)

      expect(page.current_path).to eq(root_path)
    end
  end
end
