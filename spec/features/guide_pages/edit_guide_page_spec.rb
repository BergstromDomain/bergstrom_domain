# spec/features/guide_pages/edit_guide_page_spec.rb

require "rails_helper"

RSpec.describe "Edit Guide Page", type: :feature do
  let(:admin)          { create(:user, :admin) }
  let!(:guide_page)    { create(:guide_page, title: "Getting Started", app_section: "core", body: "Welcome.") }

  before { sign_in_as(admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Updates the title and regenerates the slug" do
      gp = create(:guide_page, title: "Fitness Guide", app_section: "admin", body: "Body.")
      visit edit_guide_page_path(gp)
      fill_in "Title", with: "Sport Guide"
      click_button "Update Guide Page"
      gp.reload
      expect(page).to have_current_path(guide_page_path(gp))
      expect(page).to have_selector("h1.page-title", text: "Sport Guide")
      expect(gp.slug).to eq("sport-guide")
    end

    it "Updates the body and shows the new rendered body on the show page" do
      gp = create(:guide_page, title: "Sport Guide", app_section: "admin", body: "Old body.")
      visit edit_guide_page_path(gp)
      fill_in "Body", with: "**New body.**"
      click_button "Update Guide Page"
      expect(page).to have_selector("[data-testid='guide-page-body'] strong", text: "New body.")
    end

    it "Shows the edit form heading with the guide page title" do
      visit edit_guide_page_path(guide_page)
      expect(page).to have_selector("h1.page-title", text: "Getting Started")
    end

    it "Pre-populates the title field" do
      visit edit_guide_page_path(guide_page)
      expect(page).to have_field("Title", with: "Getting Started")
    end

    it "Pre-populates the app section field" do
      visit edit_guide_page_path(guide_page)
      expect(page).to have_select("App Section", selected: "Core")
    end

    it "Pre-populates the body field" do
      visit edit_guide_page_path(guide_page)
      expect(page).to have_field("Body", with: "Welcome.")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error when updated title is already taken" do
      create(:guide_page, title: "Chronicle Guide", app_section: "blog_posts", body: "Body.")
      gp = create(:guide_page, title: "Sport Guide", app_section: "admin", body: "Body.")
      visit edit_guide_page_path(gp)
      fill_in "Title", with: "Chronicle Guide"
      click_button "Update Guide Page"
      expect(page).to have_content("has already been taken")
      gp.reload
      expect(gp.title).to eq("Sport Guide")
    end

    it "Redirects 'Charlie Content Creator' to the guide pages index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit edit_guide_page_path(guide_page)
      expect(page).to have_current_path(guide_pages_path)
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      click_button "Sign Out"
      visit edit_guide_page_path(guide_page)
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Old slug resolves to the record after a title change" do
      gp = create(:guide_page, title: "Fitness Guide", app_section: "admin", body: "Body.")
      old_slug = gp.slug
      visit edit_guide_page_path(gp)
      fill_in "Title", with: "Sport Guide"
      click_button "Update Guide Page"
      visit guide_page_path(old_slug)
      expect(page).to have_selector("h1.page-title", text: "Sport Guide")
    end

    it "Re-renders the form with entered values when validation fails" do
      gp = create(:guide_page, title: "Sport Guide", app_section: "admin", body: "Body.")
      visit edit_guide_page_path(gp)
      fill_in "Title", with: ""
      click_button "Update Guide Page"
      expect(page).to have_field("Body", with: "Body.")
    end

    it "Allows changing the App Section to one already used by another guide page" do
      create(:guide_page, title: "Classification", app_section: "admin")
      gp = create(:guide_page, title: "Sport Guide", app_section: "core", body: "Body.")
      visit edit_guide_page_path(gp)
      select "Admin", from: "App Section"
      click_button "Update Guide Page"
      expect(page).to have_selector("[data-testid='guide-page-app-section']", text: "Admin")
      expect(GuidePage.where(app_section: "admin").count).to eq(2)
    end

    it "Allows 'Sam SysAdmin' to edit a guide page" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit edit_guide_page_path(guide_page)
      fill_in "Title", with: "Getting Started With BergstromDomain"
      click_button "Update Guide Page"
      expect(page).to have_selector("h1.page-title", text: "Getting Started With BergstromDomain")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Preserves the app section when only the title is changed" do
      visit edit_guide_page_path(guide_page)
      fill_in "Title", with: "Getting Started With BergstromDomain"
      click_button "Update Guide Page"
      expect(page).to have_selector("[data-testid='guide-page-app-section']", text: "Core")
    end
  end
end
