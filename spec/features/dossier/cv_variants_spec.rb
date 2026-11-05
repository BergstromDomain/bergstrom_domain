# spec/features/dossier/cv_variants_spec.rb
require "rails_helper"

RSpec.describe "Dossier CV Variants", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:uno)     { create(:user) }

  before { create(:dossier_profile, user: charlie, summary: "Test lead.", summary_first_person: "I lead test teams.") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates a CV Variant and shows its settings" do
      sign_in_as(charlie)
      visit new_dossier_cv_variant_path

      expect(page).to have_selector("h1.page-title", text: "Create A CV Variant")
      fill_in "Name", with: "QE Lead — Acme, Oct 2026"
      fill_in "Target Company", with: "Acme"
      fill_in "Target Role", with: "QE Lead"
      select "Implied", from: "Voice"
      select "4", from: "Minimum Importance"
      check "Show Tech Stack"
      fill_in "Job Description", with: "Lead a team of five testers."
      click_button "Create CV Variant"

      expect(page).to have_css("[data-testid='flash-success']", text: "QE Lead — Acme, Oct 2026 has been successfully created")
      expect(page).to have_selector("h1.page-title", text: "QE Lead — Acme, Oct 2026")
      expect(page).to have_selector("[data-testid='cv-variant-target']", text: "QE Lead at Acme")
      expect(page).to have_selector("[data-testid='cv-variant-voice']", text: "Implied")
      expect(page).to have_selector("[data-testid='cv-variant-style']", text: "Classic")
      expect(page).to have_selector("[data-testid='cv-variant-min-importance']", text: "4 or higher")
      expect(page).to have_selector("[data-testid='cv-variant-tech-stack']", text: "Shown")
      expect(page).to have_selector("[data-testid='cv-variant-summary']", text: "Test lead.")
      expect(page).to have_selector("[data-testid='cv-variant-job-description']", text: "Lead a team of five testers.")
    end

    it "Shows what's included and downloads the Word file" do
      job = create(:dossier_engagement, :current, user: charlie, position_title: "Test Consultant")
      assignment = create(:dossier_assignment, engagement: job, end_month: "")
      create(:dossier_achievement, assignment: assignment, importance: 4)
      create(:dossier_achievement, assignment: assignment, importance: 1)
      create(:dossier_engagement, user: charlie, start_month: "2010-01", end_month: "2012-12")
      create(:dossier_credential, :certification, user: charlie)
      variant = create(:dossier_cv_variant, user: charlie, name: "Acme")
      sign_in_as(charlie)
      visit dossier_cv_variant_path(variant)

      within("[data-testid='cv-variant-included']") do
        expect(page).to have_text("2 Engagements (1 condensed)")
        expect(page).to have_text("1 Achievement")
        expect(page).to have_text("0 Personal Projects")
        expect(page).to have_text("1 Credential")
      end
      click_link "Download Word"

      expect(page.response_headers["Content-Disposition"]).to include("_CV_Acme_")
    end

    it "Lists your CV Variants and edits one" do
      variant = create(:dossier_cv_variant, user: charlie, name: "Acme")
      create(:dossier_cv_variant, user: charlie, name: "Bravo")
      sign_in_as(charlie)
      visit dossier_cv_variants_path

      expect(page.all("[data-testid='cv-variant-row'] a.data-table__name-link").map(&:text)).to eq([ "Acme", "Bravo" ])
      click_link "Acme"
      click_link "Edit CV Variant"
      fill_in "Summary Override", with: "Tailored for Acme."
      click_button "Save CV Variant"

      expect(page).to have_current_path(dossier_cv_variant_path(variant))
      expect(page).to have_selector("[data-testid='cv-variant-summary']", text: "Tailored for Acme.")
    end

    it "Copies a CV Variant: its settings fill the form, and its ticks come along" do
      original = create(:dossier_cv_variant, user: charlie, name: "Acme", voice: "third_person", min_importance: 2)
      original.items.create!(item: create(:dossier_engagement, user: charlie), included: false)
      sign_in_as(charlie)
      visit dossier_cv_variant_path(original)
      click_link "Copy CV Variant"

      expect(page).to have_field("Name", with: "Acme (Copy)")
      expect(page).to have_select("Voice", selected: "Third Person")
      expect(page).to have_select("Copy From", selected: "Acme")
      fill_in "Name", with: "Acme v2"
      click_button "Create CV Variant"

      copy = Dossier::CvVariant.find_by!(name: "Acme v2")
      expect(copy).to have_attributes(based_on: original, voice: "third_person", min_importance: 2)
      expect(copy.items.count).to eq(1)
      expect(page).to have_selector("[data-testid='cv-variant-based-on']", text: "Acme")
    end

    it "Deletes a CV Variant" do
      variant = create(:dossier_cv_variant, user: charlie, name: "Acme")
      sign_in_as(charlie)
      visit dossier_cv_variant_path(variant)
      click_button "Delete CV Variant"

      expect(page).to have_current_path(dossier_cv_variants_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Acme has been successfully deleted")
      expect(Dossier::CvVariant.exists?(variant.id)).to be(false)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error without a name" do
      sign_in_as(charlie)
      visit new_dossier_cv_variant_path
      click_button "Create CV Variant"

      expect(page).to have_selector("[data-testid='field-error']", text: "can't be blank")
    end

    it "Turns away an App User" do
      sign_in_as(uno)
      visit dossier_cv_variants_path

      expect(page).to have_current_path(dossier_path)
    end

    it "Hides another user's CV Variant and doesn't offer it to copy" do
      theirs = create(:dossier_cv_variant, user: chris, name: "Chris's CV")
      sign_in_as(charlie)
      visit dossier_cv_variant_path(theirs)

      expect(page).to have_current_path(dossier_cv_variants_path)
      visit new_dossier_cv_variant_path(copy_from: theirs.id)
      expect(page).not_to have_select("Copy From", with_options: [ "Chris's CV" ])
      expect(find_field("Name").value.to_s).to eq("")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows the Profile summary in the chosen voice when there's no override" do
      variant = create(:dossier_cv_variant, user: charlie, voice: "first_person")
      sign_in_as(charlie)
      visit dossier_cv_variant_path(variant)

      expect(page).to have_selector("[data-testid='cv-variant-summary']", text: "I lead test teams.")
      expect(page).to have_selector("[data-testid='cv-variant-summary-source']", text: "From your Profile, first person")
    end

    it "Lets an Admin read someone's CV Variant" do
      variant = create(:dossier_cv_variant, user: charlie, name: "Acme")
      sign_in_as(create(:user, :admin))
      visit dossier_cv_variant_path(variant)

      expect(page).to have_selector("h1.page-title", text: "Acme")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows an empty state with no CV Variants" do
      sign_in_as(charlie)
      visit dossier_cv_variants_path

      expect(page).to have_selector("[data-testid='empty-state']", text: "No CV Variants yet")
    end

    it "Rejects a name already used, whatever the case" do
      create(:dossier_cv_variant, user: charlie, name: "Acme")
      sign_in_as(charlie)
      visit new_dossier_cv_variant_path
      fill_in "Name", with: "ACME"
      click_button "Create CV Variant"

      expect(page).to have_selector("[data-testid='field-error']", text: "has already been taken")
    end
  end
end
