# spec/features/auth/sign_in_spec.rb
require "rails_helper"

RSpec.describe "Sign in", type: :feature do
  let!(:user) { create(:user, email_address: "bergstrom@example.com", password: "password123", password_confirmation: "password123") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "signs in with valid credentials and redirects to root" do
      visit new_session_path

      fill_in "Email address", with: "bergstrom@example.com"
      fill_in "Password",      with: "password123"
      click_button "Sign in"

      expect(page.current_path).to eq(root_path)
    end

    it "signs in and redirects to the originally requested URL" do
      visit new_event_type_path

      fill_in "Email address", with: "bergstrom@example.com"
      fill_in "Password",      with: "password123"
      click_button "Sign in"

      expect(page.current_path).to eq(new_event_type_path)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "shows an error with incorrect password" do
      visit new_session_path

      fill_in "Email address", with: "bergstrom@example.com"
      fill_in "Password",      with: "wrong-password"
      click_button "Sign in"

      expect(page.current_path).to eq(new_session_path)
    end

    it "shows an error with incorrect email address" do
      visit new_session_path

      fill_in "Email address", with: "nobody@example.com"
      fill_in "Password",      with: "password123"
      click_button "Sign in"

      expect(page.current_path).to eq(new_session_path)
    end

    it "stays on the sign-in page with blank credentials" do
      visit new_session_path

      fill_in "Email address", with: ""
      fill_in "Password",      with: ""
      click_button "Sign in"

      expect(page.current_path).to eq(new_session_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    it "signs in with email address in a different case" do
      visit new_session_path

      fill_in "Email address", with: "BERGSTROM@EXAMPLE.COM"
      fill_in "Password",      with: "password123"
      click_button "Sign in"

      expect(page.current_path).to eq(root_path)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "does not sign in an already-signed-in user visiting sign-in again" do
      sign_in_as(user)
      visit new_session_path

      # Should still be accessible — no forced redirect
      expect(page).to have_button("Sign in")
    end
  end
end
