# spec/features/dossier/import_spec.rb
require "rails_helper"

RSpec.describe "Dossier Import", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:uno)     { create(:user) }

  let!(:consultant) { create(:dossier_employment_type, name: "Consultant") }
  let!(:test_lead)  { create(:dossier_role, name: "Test Lead") }
  let!(:brisbane)   { create(:dossier_location, city: "Brisbane", country: "Australia") }

  def fixture(name) = Rails.root.join("spec/fixtures/files/imports/dossier", name)
  def fixture_text(name) = File.read(fixture(name))

  def upload(name)
    visit new_dossier_import_path
    attach_file "Master CV file", fixture(name)
    click_button "Preview Import"
  end

  def count_row(kind) = find("[data-testid='import-count-row']", text: kind)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Previews the import without changing anything, then imports on confirm" do
      sign_in_as(charlie)
      upload("master_cv.yaml")

      expect(page).to have_selector("h1", text: "Import Preview")
      expect(count_row("Engagement")).to have_text("1 new")
      expect(count_row("Organisation")).to have_text("2 new")
      expect(Dossier::Engagement.count).to eq(0)

      click_button "Import"

      expect(page).to have_current_path(dossier_engagements_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Master CV imported: 1 Profile, 2 Organisations")
      expect(page).to have_selector("[data-testid='engagement-card']", text: "Test Consultant")
      expect(charlie.dossier_engagements.sole.assignments.sole.summary).to eq("Led testing of the licensing system.")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Sends a visitor to sign in" do
      visit new_dossier_import_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Keeps an App User out" do
      sign_in_as(uno)
      visit new_dossier_import_path

      expect(page).to have_current_path(dossier_path)
      expect(page).to have_content("Not authorised.")
    end

    it "Asks for a file when none is chosen" do
      sign_in_as(charlie)
      visit new_dossier_import_path
      click_button "Preview Import"

      expect(page).to have_content("Please choose a YAML file to import.")
    end

    it "Refuses a file that isn't YAML" do
      sign_in_as(charlie)
      visit new_dossier_import_path
      attach_file "Master CV file", Rails.root.join("spec/fixtures/files/imports/not_a_csv.txt")
      click_button "Preview Import"

      expect(page).to have_content("The file must be a YAML file (.yaml or .yml).")
    end

    it "Lists errors and offers no Import button" do
      sign_in_as(charlie)
      upload("unknown_type.yaml")

      expect(page).to have_selector("[data-testid='import-error']", text: "unknown Employment Type 'Freelancer'")
      expect(page).not_to have_button("Import")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Shows what already exists on a second upload, with nothing left to import" do
      Dossier::Import.new(charlie, fixture_text("master_cv.yaml")).import!
      sign_in_as(charlie)
      upload("master_cv.yaml")

      expect(count_row("Engagement")).to have_text("1 already exists")
      expect(page).to have_content("Nothing new to import.")
      expect(page).not_to have_button("Import")
    end

    it "Shows warnings, and still imports" do
      sign_in_as(charlie)
      upload("master_cv.yaml")

      expect(page).to have_selector("[data-testid='import-warning']", text: "Skill Category 'Test Automation' is unknown")
      expect(page).to have_button("Import")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Links to the import from the left nav" do
      sign_in_as(charlie)
      visit dossier_path
      click_link "Import Master CV"

      expect(page).to have_current_path(new_dossier_import_path)
    end

    it "Imports what was previewed even if the page sat open" do
      sign_in_as(charlie)
      upload("master_cv.yaml")
      Dossier::Import.new(charlie, fixture_text("master_cv.yaml")).import! # e.g. another tab

      click_button "Import"

      expect(page).to have_css("[data-testid='flash-info']", text: "Nothing new to import")
      expect(Dossier::Engagement.count).to eq(1)
    end
  end
end
