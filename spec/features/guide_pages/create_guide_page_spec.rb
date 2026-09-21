# spec/features/guide_pages/create_guide_page_spec.rb

require "rails_helper"

RSpec.describe "Create Guide Page", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in_as(admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates a guide page with all required fields" do
      visit new_guide_page_path
      select "Core", from: "App Section"
      fill_in "Title", with: "Getting Started"
      fill_in "Body",  with: "Welcome to BergstromDomain."
      click_button "Create Guide Page"

      expect(page).to have_selector("h1.page-title", text: "Getting Started")
      expect(page).to have_selector("[data-testid='guide-page-app-section']", text: "Core")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error when title is missing" do
      visit new_guide_page_path
      select "Core", from: "App Section"
      fill_in "Body", with: "Something."
      click_button "Create Guide Page"

      expect(page).to have_selector("[data-testid='field-error']")
      expect(page).to have_content("can't be blank")
      expect(GuidePage.count).to eq(0)
    end

    it "Shows an error when title is a duplicate (same case)" do
      create(:guide_page, title: "Getting Started", app_section: "core")
      visit new_guide_page_path
      select "Chronicle", from: "App Section"
      fill_in "Title", with: "Getting Started"
      fill_in "Body",  with: "Another guide."
      click_button "Create Guide Page"

      expect(page).to have_content("has already been taken")
      expect(GuidePage.count).to eq(1)
    end

    it "Shows an error when app section is missing" do
      visit new_guide_page_path
      fill_in "Title", with: "Getting Started"
      fill_in "Body",  with: "Welcome."
      click_button "Create Guide Page"

      expect(page).to have_selector("[data-testid='field-error']")
      expect(page).to have_content("can't be blank")
      expect(GuidePage.count).to eq(0)
    end

    it "Shows an error when body is missing" do
      visit new_guide_page_path
      select "Core", from: "App Section"
      fill_in "Title", with: "Getting Started"
      click_button "Create Guide Page"

      expect(page).to have_selector("[data-testid='field-error']")
      expect(page).to have_content("can't be blank")
      expect(GuidePage.count).to eq(0)
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      click_button "Sign Out"
      visit new_guide_page_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Redirects 'Charlie Content Creator' to the guide pages index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit new_guide_page_path
      expect(page).to have_current_path(guide_pages_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Re-renders the form with entered values when validation fails" do
      visit new_guide_page_path
      fill_in "Title", with: "Getting Started"
      fill_in "Body",  with: "Welcome."
      click_button "Create Guide Page"

      expect(page).to have_field("Title", with: "Getting Started")
      expect(page).to have_field("Body", with: "Welcome.")
    end

    it "Allows creating a second guide page under the same App Section" do
      create(:guide_page, title: "Classification", app_section: "core")
      visit new_guide_page_path
      select "Core", from: "App Section"
      fill_in "Title", with: "Sign Up"
      fill_in "Body",  with: "How to create an account."
      click_button "Create Guide Page"

      expect(page).to have_selector("h1.page-title", text: "Sign Up")
      expect(GuidePage.where(app_section: "core").count).to eq(2)
    end

    it "Allows 'Sam SysAdmin' to create a guide page" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit new_guide_page_path
      select "Core", from: "App Section"
      fill_in "Title", with: "Getting Started"
      fill_in "Body",  with: "Welcome."
      click_button "Create Guide Page"

      expect(page).to have_selector("h1.page-title", text: "Getting Started")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Renders Markdown in the body as HTML once created" do
      visit new_guide_page_path
      select "Core", from: "App Section"
      fill_in "Title", with: "Getting Started"
      fill_in "Body",  with: "**bold text**"
      click_button "Create Guide Page"

      expect(page).to have_selector("[data-testid='guide-page-body'] strong", text: "bold text")
    end
  end
end
