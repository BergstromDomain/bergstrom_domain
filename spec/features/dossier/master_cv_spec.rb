# spec/features/dossier/master_cv_spec.rb
require "rails_helper"

RSpec.describe "Dossier Download Master CV", type: :feature do
  let(:charlie) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Opens from the left nav and downloads the Word file" do
      create(:dossier_profile, user: charlie, display_name: "Alex Example")
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Download Master CV" }

      expect(page).to have_selector("h1.page-title", text: "Download Master CV")
      click_link "Download Word"

      expect(page.response_headers["Content-Type"]).to include("wordprocessingml.document")
      expect(page.response_headers["Content-Disposition"]).to include("Alex_Example_CV_")
    end

    it "Downloads the PDF" do
      create(:dossier_profile, user: charlie, display_name: "Alex Example")
      sign_in_as(charlie)
      visit dossier_master_cv_path
      click_link "Download PDF"

      expect(page.response_headers["Content-Type"]).to include("application/pdf")
      expect(page.response_headers["Content-Disposition"]).to include("Alex_Example_CV_")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Turns away an App User, who sees no link to it" do
      sign_in_as(create(:user))
      visit dossier_path

      expect(page).not_to have_link("Download Master CV")
      visit dossier_master_cv_path
      expect(page).to have_current_path(dossier_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Asks for a Profile first, with no download buttons" do
      sign_in_as(charlie)
      visit dossier_master_cv_path

      expect(page).to have_selector("[data-testid='master-cv-no-profile']", text: "Create your Profile first")
      expect(page).not_to have_link("Download Word")
      click_link "Create Your Profile"
      expect(page).to have_current_path(edit_dossier_profile_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Says what the CV holds, counting only the user's own records" do
      create(:dossier_profile, user: charlie)
      create_list(:dossier_engagement, 2, user: charlie)
      create(:dossier_engagement, :personal, user: charlie)
      create(:dossier_credential, user: charlie)
      create(:dossier_engagement) # someone else's
      sign_in_as(charlie)
      visit dossier_master_cv_path

      expect(page).to have_selector("[data-testid='master-cv-contents']",
                                    text: "2 Engagements, 1 Personal Project, and 1 Credential")
    end
  end
end
