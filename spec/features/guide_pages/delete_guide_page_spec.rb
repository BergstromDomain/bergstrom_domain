# spec/features/guide_pages/delete_guide_page_spec.rb

require "rails_helper"

RSpec.describe "Delete Guide Page", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in_as(admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Deletes a guide page and redirects to index" do
      gp = create(:guide_page, title: "Getting Started", app_section: "core", body: "Welcome.")
      visit guide_page_path(gp)
      click_button "Delete Guide Page"
      expect(page).to have_current_path(guide_pages_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Getting Started has been successfully deleted")
      expect(page).to have_no_css("[data-testid='guide-page-table']", text: "Getting Started")
    end

    it "Removes the guide page from the database" do
      gp = create(:guide_page, title: "Getting Started", app_section: "core", body: "Welcome.")
      visit guide_page_path(gp)
      expect {
        click_button "Delete Guide Page"
      }.to change(GuidePage, :count).by(-1)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Does not show the 'Delete' button to 'Charlie Content Creator'" do
      gp = create(:guide_page, title: "Getting Started", app_section: "core", body: "Welcome.")
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit guide_page_path(gp)
      expect(page).not_to have_button("Delete Guide Page")
    end

    it "Does not show the 'Delete' button to 'Gary Guest'" do
      gp = create(:guide_page, title: "Getting Started", app_section: "core", body: "Welcome.")
      click_button "Sign Out"
      visit guide_page_path(gp)
      expect(page).not_to have_button("Delete Guide Page")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Allows 'Sam SysAdmin' to delete a guide page" do
      gp = create(:guide_page, title: "Getting Started", app_section: "core", body: "Welcome.")
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit guide_page_path(gp)
      click_button "Delete Guide Page"
      expect(page).to have_current_path(guide_pages_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows the 'Delete Guide Page' button to an 'Adam Admin'" do
      gp = create(:guide_page, title: "Getting Started", app_section: "core", body: "Welcome.")
      visit guide_page_path(gp)
      expect(page).to have_button("Delete Guide Page")
    end
  end
end
