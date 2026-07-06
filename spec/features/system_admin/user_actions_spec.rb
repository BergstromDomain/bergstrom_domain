# spec/features/system_admin/user_actions_spec.rb
require "rails_helper"

RSpec.describe "System Admin — User Actions", type: :feature do
  let!(:sam)             { create(:user, :system_admin) }
  let!(:pending_user)    { create(:user, first_name: "Pat",  status: "pending") }
  let!(:active_user)     { create(:user, first_name: "Alex", status: "active") }
  let!(:suspended_user)  { create(:user, first_name: "Sue",  status: "suspended") }

  describe "Happy Path" do
    it "Approves a pending user" do
      sign_in_as sam
      visit system_admin_user_path(pending_user)

      click_button "Approve"

      expect(page).to have_current_path(system_admin_user_path(pending_user))
      expect(page).to have_css("[data-testid='flash-notice']")
      expect(pending_user.reload.status).to eq("active")
    end

    it "Sends an approval email" do
      sign_in_as sam
      visit system_admin_user_path(pending_user)

      expect {
        click_button "Approve"
      }.to have_enqueued_mail(UserMailer, :approved)
    end

    it "Rejects a pending user and removes the record" do
      sign_in_as sam
      visit system_admin_user_path(pending_user)

      expect { click_button "Reject" }.to change(User, :count).by(-1)

      expect(page).to have_current_path(system_admin_users_path)
      expect(page).to have_css("[data-testid='flash-notice']")
    end

    it "Suspends an active user" do
      sign_in_as sam
      visit system_admin_user_path(active_user)

      click_button "Suspend"

      expect(page).to have_current_path(system_admin_user_path(active_user))
      expect(active_user.reload.status).to eq("suspended")
    end

    it "Sends a suspension email" do
      sign_in_as sam
      visit system_admin_user_path(active_user)

      expect {
        click_button "Suspend"
      }.to have_enqueued_mail(UserMailer, :suspended)
    end

    it "Reactivates a suspended user" do
      sign_in_as sam
      visit system_admin_user_path(suspended_user)

      click_button "Reactivate"

      expect(page).to have_current_path(system_admin_user_path(suspended_user))
      expect(suspended_user.reload.status).to eq("active")
    end

    it "Changes a user's role" do
      sign_in_as sam
      visit system_admin_user_path(active_user)

      select "Content creator", from: "role"
      click_button "Update Role"

      expect(page).to have_css("[data-testid='flash-notice']")
      expect(active_user.reload.role).to eq("content_creator")
    end
  end

  describe "Edge Cases" do
    it "Does not show a Suspend button for the signed-in system admin" do
      sign_in_as sam
      visit system_admin_user_path(sam)

      expect(page).not_to have_css("[data-testid='suspend-button']")
    end
  end
end
