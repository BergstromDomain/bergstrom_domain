# spec/features/dossier/employment_type_engagements_spec.rb
require "rails_helper"

# An Engagement's Employment Type links to its page, which lists the signed-in
# user's own Engagements of that type, newest first, with their Assignments.
RSpec.describe "Dossier Employment Type Engagements", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }

  let(:consultant) { create(:dossier_employment_type, name: "Consultant") }
  let(:contractor) { create(:dossier_employment_type, name: "Contractor") }
  let(:qbcc) { create(:dossier_organisation, name: "Queensland Building and Construction Commission", abbreviation: "QBCC") }

  def engagement(user: charlie, type: consultant, title: "Test Manager", **dates)
    create(:dossier_engagement, user: user, employment_type: type, position_title: title, **dates)
  end

  def panel = find("[data-testid='your-engagements']")
  def listed = panel.all("[data-testid='your-engagement']").map { |item| item.find("[data-testid='your-engagement-title']").text }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Takes Charlie from a Timeline card's Employment Type to their Consultant Engagements, newest first" do
      older = engagement(title: "Test Analyst", start_on: Date.new(2015, 1, 1), end_on: Date.new(2016, 1, 1))
      newer = engagement(start_on: Date.new(2024, 9, 1), end_on: Date.new(2025, 6, 1))
      create(:dossier_assignment, engagement: newer, client: qbcc, project: "Digital Licencing",
                                  start_on: Date.new(2024, 9, 1), end_on: Date.new(2025, 6, 1))
      sign_in_as(charlie)
      visit dossier_engagements_path

      within(all("[data-testid='engagement-card']").first) { click_link "Consultant" }

      expect(page).to have_current_path(dossier_employment_type_path(consultant))
      expect(listed).to eq([ newer.to_toast_label, older.to_toast_label ])
      expect(panel).to have_link("QBCC - Digital Licencing")
    end

    it "Links the Employment Type on the Engagement page" do
      record = engagement
      sign_in_as(charlie)
      visit dossier_engagement_path(record)

      within("[data-testid='engagement-employment-type']") { click_link "Consultant" }

      expect(page).to have_current_path(dossier_employment_type_path(consultant))
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Never shows Chris Charlie's Engagements" do
      engagement
      mine = engagement(user: chris, title: "Test Lead")
      sign_in_as(chris)
      visit dossier_employment_type_path(consultant)

      expect(listed).to eq([ mine.to_toast_label ])
    end

    it "Shows Gary the Employment Type without a Your Engagements panel" do
      engagement
      visit dossier_employment_type_path(consultant)

      expect(page).to have_selector("[data-testid='reference-data-name']", text: "Consultant")
      expect(page).not_to have_selector("[data-testid='your-engagements']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lists only Engagements of the page's Employment Type" do
      engagement(type: contractor, title: "Test Specialist")
      consulting = engagement
      sign_in_as(charlie)
      visit dossier_employment_type_path(consultant)

      expect(listed).to eq([ consulting.to_toast_label ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves out deleted Engagements, and the panel when none are left" do
      engagement.soft_delete!
      sign_in_as(charlie)
      visit dossier_employment_type_path(consultant)

      expect(page).not_to have_selector("[data-testid='your-engagements']")
    end
  end
end
