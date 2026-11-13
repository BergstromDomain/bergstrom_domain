# spec/features/dossier/organisation_logos_spec.rb
require "rails_helper"

# An Organisation's logo: uploaded on its form, shown on its page and the
# Organisations list, by an Assignment's title (the client's) and on the
# Timeline (the employer's on each Engagement, the client's on each
# Assignment). Without one, a building icon stands in, like the person icon
# for a Person without a photo.
RSpec.describe "Dossier Organisation logos", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:adam)    { create(:user, :admin) }

  let(:qpt) { create(:dossier_organisation, name: "Queensland Public Trustee", abbreviation: "QPT") }
  let(:apa) { create(:dossier_organisation, name: "APA Group") }

  def with_logo(organisation, fixture = "test_image.png")
    organisation.logo.attach(file_fixture(fixture))
    organisation
  end

  def logo_in(scope) = scope.find("img[data-testid='organisation-logo']")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds a logo on New Organisation, shown on its page" do
      sign_in_as(adam)
      visit new_dossier_organisation_path
      fill_in "Name", with: "Queensland Public Trustee"
      attach_file "Logo", file_fixture("test_image.png")
      click_button "Create Organisation"

      expect(page).to have_css("[data-testid='flash-success']", text: "Queensland Public Trustee has been successfully created")
      expect(logo_in(find(".page-header"))[:alt]).to eq("Queensland Public Trustee logo")
    end

    it "Replaces the logo on Edit, then removes it with Remove Logo" do
      with_logo(qpt)
      sign_in_as(adam)
      visit edit_dossier_organisation_path(qpt)
      attach_file "Logo", file_fixture("test_image.jpg")
      click_button "Update Organisation"
      expect(qpt.reload.logo.filename.to_s).to eq("test_image.jpg")

      visit edit_dossier_organisation_path(qpt)
      check "Remove Logo"
      click_button "Update Organisation"

      expect(page).to have_css(".page-header [data-testid='organisation-logo-placeholder']")
      expect(qpt.reload.logo).not_to be_attached
    end

    it "Shows each Organisation's logo, or the placeholder, on the Organisations list" do
      with_logo(qpt)
      apa
      visit dossier_organisations_path

      qpt_row = find("[data-testid='reference-data-row']", text: "Queensland Public Trustee")
      apa_row = find("[data-testid='reference-data-row']", text: "APA Group")
      expect(qpt_row).to have_css("img[data-testid='organisation-logo']")
      expect(apa_row).to have_css("[data-testid='organisation-logo-placeholder'] svg")
    end

    it "Shows the client's logo by the title of Charlie's Assignment" do
      engagement = create(:dossier_engagement, user: charlie, employer: apa)
      assignment = create(:dossier_assignment, engagement: engagement, client: with_logo(qpt))
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      expect(logo_in(find(".page-header"))[:alt]).to eq("Queensland Public Trustee logo")
    end

    it "Shows the employer's logo on each Timeline Engagement, and the client's on each Assignment" do
      engagement = create(:dossier_engagement, user: charlie, employer: with_logo(apa))
      create(:dossier_assignment, engagement: engagement, client: with_logo(qpt))
      sign_in_as(charlie)
      visit dossier_engagements_path

      expect(logo_in(find("[data-testid='engagement-card'] .dossier-timeline-card__title"))[:alt]).to eq("APA Group logo")
      expect(logo_in(find("[data-testid='assignment-row']"))[:alt]).to eq("Queensland Public Trustee logo")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Refuses a logo that isn't a JPEG, PNG or WebP, saving nothing" do
      sign_in_as(adam)
      visit new_dossier_organisation_path
      fill_in "Name", with: "Queensland Public Trustee"
      attach_file "Logo", Rails.root.join("README.md")
      click_button "Create Organisation"

      expect(page).to have_selector("[data-testid='field-error']", text: "Logo must be a JPEG, PNG or WebP")
      expect(Dossier::Organisation.count).to eq(0)
    end

    it "Shows Gary the logo on an Organisation's page" do
      with_logo(qpt)
      visit dossier_organisation_path(qpt)

      expect(page).to have_css(".page-header img[data-testid='organisation-logo']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lets Charlie add a logo when creating an Organisation" do
      sign_in_as(charlie)
      visit new_dossier_organisation_path
      fill_in "Name", with: "APA Group"
      attach_file "Logo", file_fixture("test_image.jpg")
      click_button "Create Organisation"

      expect(Dossier::Organisation.find_by!(name: "APA Group").logo).to be_attached
    end

    it "Keeps the logo when Edit is saved without a new file" do
      with_logo(qpt)
      sign_in_as(adam)
      visit edit_dossier_organisation_path(qpt)
      fill_in "Abbreviation", with: "PT"
      click_button "Update Organisation"

      expect(qpt.reload).to have_attributes(abbreviation: "PT")
      expect(qpt.logo).to be_attached
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows the placeholder, not a broken image, wherever an Organisation has no logo" do
      engagement = create(:dossier_engagement, user: charlie, employer: apa)
      assignment = create(:dossier_assignment, engagement: engagement, client: qpt)
      sign_in_as(charlie)

      visit dossier_engagements_path
      expect(page).not_to have_css("img[data-testid='organisation-logo']")
      expect(find("[data-testid='engagement-card'] .dossier-timeline-card__title"))
        .to have_css("[data-testid='organisation-logo-placeholder'][title='APA Group']")
      expect(find("[data-testid='assignment-row']")).to have_css("[data-testid='organisation-logo-placeholder']")

      visit dossier_assignment_path(assignment)
      expect(find(".page-header")).to have_css("[data-testid='organisation-logo-placeholder']")
    end

    it "Offers no Remove Logo on New, or on Edit without a logo" do
      sign_in_as(adam)
      visit new_dossier_organisation_path
      expect(page).not_to have_field("Remove Logo")

      visit edit_dossier_organisation_path(qpt)
      expect(page).not_to have_field("Remove Logo")
    end
  end
end
