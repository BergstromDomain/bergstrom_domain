# spec/features/dossier/experience_spec.rb
require "rails_helper"

RSpec.describe "Dossier Experience", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:uno)     { create(:user) }

  let!(:government) { create(:dossier_industry, name: "Government") }
  let!(:northwind)  { create(:dossier_organisation, name: "Northwind Transport Authority", abbreviation: "NTA", industry: government) }
  let!(:acme)       { create(:dossier_organisation, name: "Acme Consulting") }
  let!(:consultant) { create(:dossier_employment_type, name: "Consultant") }
  let!(:test_lead)  { create(:dossier_role, name: "Test Lead") }
  let!(:engagement) do
    create(:dossier_engagement, user: charlie, employer: acme, employment_type: consultant,
                                start_month: "2015-01", end_month: "2022-12")
  end
  let!(:ticketing) do
    create(:dossier_assignment, engagement: engagement, client: northwind, role: test_lead,
                                start_month: "2015-01", end_month: "2017-12")
  end

  def section(name) = find("[data-testid='experience-#{name}']")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the career totals and a table per slice, linking each row to its page" do
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Experience" }

      expect(page).to have_selector("h1.page-title", text: "Experience")
      expect(page).to have_selector("[data-testid='experience-career']", text: "8+ years")
      expect(page).to have_selector("[data-testid='experience-on-assignments']", text: "3+ years")
      expect(page).to have_selector("[data-testid='experience-personal']", text: "—")

      within(section("employers")) do
        row = find("[data-testid='experience-row']")
        expect(row).to have_link("Acme Consulting", href: dossier_organisation_path(acme))
        expect(row).to have_text("8+ years")
        expect(row).to have_text("Jan 2015 – Dec 2022")
      end
      expect(section("clients")).to have_link("Northwind Transport Authority")
      expect(section("clients")).to have_text("3+ years")
      expect(section("industries")).to have_link("Government", href: dossier_industry_path(government))
      expect(section("roles")).to have_link("Test Lead", href: dossier_role_path(test_lead))
      expect(section("employment-types")).to have_link("Consultant", href: dossier_employment_type_path(consultant))
      expect(page).to have_link("My Skills", href: dossier_my_skills_path)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Keeps an App User off the page" do
      sign_in_as(uno)
      visit dossier_experience_path
      expect(page).to have_current_path(dossier_path)
    end

    it "Shows another Content Creator only their own (empty) experience" do
      sign_in_as(chris)
      visit dossier_experience_path

      expect(page).to have_selector("[data-testid='empty-state']")
      expect(page).not_to have_content("Northwind")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Shows personal projects only in their own total" do
      hobby = create(:dossier_engagement, :personal, user: charlie, employer: create(:dossier_organisation, name: "Own Apps"),
                                                     start_month: "2023-01", end_month: "2023-12")
      create(:dossier_assignment, engagement: hobby, start_month: "2023-01", end_month: "2023-12")
      sign_in_as(charlie)
      visit dossier_experience_path

      expect(page).to have_selector("[data-testid='experience-personal']", text: "1+ year")
      expect(section("employers")).not_to have_content("Own Apps")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Lists Assignments without a Role under No Role, unlinked" do
      ticketing.update!(role: nil)
      sign_in_as(charlie)
      visit dossier_experience_path

      within(section("roles")) do
        expect(page).to have_selector("[data-testid='experience-row']", text: "No Role")
        expect(page).not_to have_link("No Role")
      end
    end
  end
end
