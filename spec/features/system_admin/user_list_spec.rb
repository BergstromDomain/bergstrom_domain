# spec/features/system_admin/user_list_spec.rb
require "rails_helper"

RSpec.describe "System Admin — User List", type: :feature do
  let!(:sam)     { create(:user, :system_admin) }
  let!(:uno)     { create(:user) }
  let!(:charlie) { create(:user, :content_creator) }
  let!(:pending_user) do
    create(:user,
           first_name: "Pat",
           last_name:  "Pending",
           email_address: "pat@example.com",
           status: "pending")
  end

  describe "Happy Path" do
    it "Shows the user list page" do
      sign_in_as sam
      visit system_admin_users_path

      expect(page).to have_css("h1.page-title", text: "User Management")
    end

    it "Lists all users" do
      sign_in_as sam
      visit system_admin_users_path

      expect(page).to have_css("[data-testid='user-list']")
      expect(page).to have_text(uno.email_address)
      expect(page).to have_text(charlie.email_address)
      expect(page).to have_text(pending_user.email_address)
    end

    it "Shows a pending badge for 'Pat Pending'" do
      sign_in_as sam
      visit system_admin_users_path

      within "[data-testid='user-row-#{pending_user.id}']" do
        expect(page).to have_css(".badge--pending", text: "Pending")
      end
    end

    it "Shows an active badge for active users" do
      sign_in_as sam
      visit system_admin_users_path

      within "[data-testid='user-row-#{uno.id}']" do
        expect(page).to have_css(".badge--active", text: "Active")
      end
    end

    it "Links to each user's detail page" do
      sign_in_as sam
      visit system_admin_users_path

      within "[data-testid='user-row-#{uno.id}']" do
        expect(page).to have_link("View", href: system_admin_user_path(uno))
      end
    end
  end

  describe "Negative Path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit system_admin_users_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Redirects an app_user to root with an alert" do
      sign_in_as uno
      visit system_admin_users_path

      expect(page).to have_current_path(root_path)
      expect(page).to have_css("[data-testid='flash-alert']")
    end

    it "Redirects an admin to root with an alert" do
      sign_in_as create(:user, :admin)
      visit system_admin_users_path

      expect(page).to have_current_path(root_path)
      expect(page).to have_css("[data-testid='flash-alert']")
    end
  end

  describe "Alternative Path" do
    it "Filters to show only pending users" do
      sign_in_as sam
      visit system_admin_users_path(status: "pending")

      expect(page).to have_text(pending_user.email_address)
      expect(page).not_to have_text(uno.email_address)
    end

    it "Filters to show only active users" do
      sign_in_as sam
      visit system_admin_users_path(status: "active")

      expect(page).to have_text(uno.email_address)
      expect(page).not_to have_text(pending_user.email_address)
    end
  end

  describe "Edge Cases" do
    it "Shows a message when no users match the filter" do
      sign_in_as sam
      visit system_admin_users_path(status: "suspended")

      expect(page).to have_css("[data-testid='user-list-empty']")
    end
  end
end
