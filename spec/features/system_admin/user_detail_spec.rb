# spec/features/system_admin/user_detail_spec.rb
require "rails_helper"

RSpec.describe "System Admin — User Detail", type: :feature do
  let!(:sam)           { create(:user, :system_admin) }
  let!(:pending_user)  { create(:user, first_name: "Pat",  last_name: "Pending",  status: "pending") }
  let!(:active_user)   { create(:user, first_name: "Alex", last_name: "Active",   status: "active") }
  let!(:suspended_user) { create(:user, first_name: "Sue",  last_name: "Suspended", status: "suspended") }

  describe "Happy Path" do
    it "Shows the user detail page" do
      sign_in_as sam
      visit system_admin_user_path(active_user)

      expect(page).to have_css("h1.page-title", text: "#{active_user.first_name} #{active_user.last_name}")
    end

    it "Shows the user's email address" do
      sign_in_as sam
      visit system_admin_user_path(active_user)

      expect(page).to have_css("[data-testid='user-email']", text: active_user.email_address)
    end

    it "Shows the user's role" do
      sign_in_as sam
      visit system_admin_user_path(active_user)

      expect(page).to have_css("[data-testid='user-role']")
    end

    it "Shows the user's status badge" do
      sign_in_as sam
      visit system_admin_user_path(active_user)

      expect(page).to have_css(".badge--active")
    end
  end

  describe "Negative Path" do
    it "Redirects an unauthenticated visitor to sign in" do
      visit system_admin_user_path(active_user)
      expect(page).to have_current_path(new_session_path)
    end

    it "Redirects a non-system-admin to root" do
      sign_in_as active_user
      visit system_admin_user_path(pending_user)

      expect(page).to have_current_path(root_path)
    end
  end

  describe "Alternative Path — Action Buttons by Status" do
    it "Shows Approve and Reject buttons for a pending user" do
      sign_in_as sam
      visit system_admin_user_path(pending_user)

      expect(page).to have_css("[data-testid='approve-button']")
      expect(page).to have_css("[data-testid='reject-button']")
      expect(page).not_to have_css("[data-testid='suspend-button']")
      expect(page).not_to have_css("[data-testid='reactivate-button']")
    end

    it "Shows a Suspend button for an active user" do
      sign_in_as sam
      visit system_admin_user_path(active_user)

      expect(page).to have_css("[data-testid='suspend-button']")
      expect(page).not_to have_css("[data-testid='approve-button']")
      expect(page).not_to have_css("[data-testid='reactivate-button']")
    end

    it "Shows a Reactivate button for a suspended user" do
      sign_in_as sam
      visit system_admin_user_path(suspended_user)

      expect(page).to have_css("[data-testid='reactivate-button']")
      expect(page).not_to have_css("[data-testid='approve-button']")
      expect(page).not_to have_css("[data-testid='suspend-button']")
    end
  end

  describe "Edge Cases" do
    it "Does not show a Suspend button for the current system admin" do
      sign_in_as sam
      visit system_admin_user_path(sam)

      expect(page).not_to have_css("[data-testid='suspend-button']")
    end
  end
end
