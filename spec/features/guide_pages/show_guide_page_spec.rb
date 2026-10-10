# spec/features/guide_pages/show_guide_page_spec.rb

require "rails_helper"

RSpec.describe "Show Guide Page", type: :feature do
  let(:admin)           { create(:user, :admin) }
  let(:content_creator) { create(:user, :content_creator) }
  let!(:guide_page) do
    create(:guide_page,
      title:           "Getting Started",
      app_section:     "core",
      body:            "Welcome to **BergstromDomain**.",
      supports_guest:  true,
      supports_user:   true,
      supports_content_creator: false)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit guide_page_path(guide_page) }

    it "Displays the guide page title" do
      expect(page).to have_selector("h1.page-title", text: "Getting Started")
    end

    it "Displays the app section" do
      expect(page).to have_selector("[data-testid='guide-page-app-section']", text: "Core")
    end

    it "Renders the body as sanitized HTML" do
      expect(page).to have_selector("[data-testid='guide-page-body'] strong", text: "BergstromDomain")
    end

    it "Shows the Supported For list with the right checks/x marks" do
      within("[data-testid='guide-page-support-list']") do
        expect(page).to have_selector("[data-testid='guide-page-supports_guest'] svg.classification-icon--success")
        expect(page).to have_selector("[data-testid='guide-page-supports_user'] svg.classification-icon--success")
        expect(page).to have_selector("[data-testid='guide-page-supports_content_creator'] svg.classification-icon--danger")
      end
    end

    it "Shows a back link to the index" do
      expect(page).to have_link("Back", href: guide_pages_path, exact: true)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Gary Guest'" do
      expect(page).not_to have_link("Edit Guide Page")
      expect(page).not_to have_button("Delete Guide Page")
    end

    it "Is accessible by slug" do
      visit guide_page_path(guide_page.slug)
      expect(page).to have_selector("h1.page-title", text: "Getting Started")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Returns 404 for a non-existent slug" do
      visit guide_page_path("non-existent-slug")
      expect(page).to have_http_status(:not_found)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Charlie Content Creator'" do
      sign_in_as content_creator
      visit guide_page_path(guide_page)
      expect(page).not_to have_link("Edit Guide Page")
      expect(page).not_to have_button("Delete Guide Page")
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Uno User'" do
      sign_in_as create(:user, :app_user)
      visit guide_page_path(guide_page)
      expect(page).not_to have_link("Edit Guide Page")
      expect(page).not_to have_button("Delete Guide Page")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    context "As 'Adam Admin'" do
      before do
        sign_in_as admin
        visit guide_page_path(guide_page)
      end

      it "Shows the 'Edit' button" do
        expect(page).to have_link("Edit Guide Page", href: edit_guide_page_path(guide_page))
      end

      it "Shows the 'Delete' button" do
        expect(page).to have_button("Delete Guide Page")
      end

      it "Shows the button divider between the 'Back' and the 'Edit' buttons" do
        expect(page).to have_selector(".btn-divider")
      end
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Handles a guide page with a long title without breaking layout" do
      long = create(:guide_page, title: "A" * 60, app_section: "admin")
      visit guide_page_path(long)
      expect(page).to have_selector("h1.page-title")
    end

    it "Shows both the 'Edit' and the 'Delete' buttons to 'Sam SysAdmin'" do
      sign_in_as create(:user, :system_admin)
      visit guide_page_path(guide_page)
      expect(page).to have_link("Edit Guide Page")
      expect(page).to have_button("Delete Guide Page")
    end
  end
end
