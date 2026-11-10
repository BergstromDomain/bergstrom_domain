# spec/features/dossier/assignment_partners_spec.rb
require "rails_helper"

RSpec.describe "Dossier Assignment Vendors and Customers", type: :feature do
  let(:charlie)    { create(:user, :content_creator) }
  let(:engagement) { create(:dossier_engagement, user: charlie) }
  let(:assignment) { create(:dossier_assignment, engagement: engagement) }
  let!(:pwc)       { create(:dossier_organisation, name: "PwC") }
  let!(:telstra)   { create(:dossier_organisation, name: "Telstra") }

  def panel = find("[data-testid='assignment-partners']")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds a Vendor and a Customer from the Assignment page" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      within(panel) { click_link "Add A Vendor" }

      expect(page).to have_selector("h1.page-title", text: "Add A Vendor")
      select "PwC", from: "Organisation"
      fill_in "Scope", with: "Built the Salesforce portal"
      click_button "Add Vendor"

      expect(page).to have_current_path(dossier_assignment_path(assignment))
      expect(page).to have_css("[data-testid='flash-success']", text: "PwC has been successfully created")
      within(panel) { click_link "Add A Customer" }
      expect(page).to have_selector("h1.page-title", text: "Add A Customer")
      select "Telstra", from: "Organisation"
      click_button "Add Customer"

      within(panel.find("[data-testid='vendors']")) do
        expect(page).to have_link("PwC", href: dossier_organisation_path(pwc))
        expect(page).to have_text("Built the Salesforce portal")
      end
      expect(panel.find("[data-testid='customers']")).to have_link("Telstra")
      expect(page).to have_css("[data-testid='assignment-colleagues'] #vendors[data-testid='vendors']")
      expect(page).to have_css("[data-testid='assignment-colleagues'] #customers[data-testid='customers']")
    end

    it "Edits and deletes a Vendor" do
      create(:dossier_assignment_partner, assignment: assignment, organisation: pwc)
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      within(panel.find("[data-testid='vendors']")) { click_link "Edit" }

      expect(page).to have_selector("h1.page-title", text: "Edit Vendor")
      fill_in "Scope", with: "Data migration"
      click_button "Save Vendor"
      expect(panel).to have_text("Data migration")

      within(panel.find("[data-testid='vendors']")) { click_button "Delete" }
      expect(page).to have_css("[data-testid='flash-success']", text: "PwC has been successfully deleted")
      expect(panel.find("[data-testid='vendors']")).to have_text("No Vendors yet.")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Rejects the same Vendor twice" do
      create(:dossier_assignment_partner, assignment: assignment, organisation: pwc)
      sign_in_as(charlie)
      visit new_dossier_assignment_partner_path(assignment, kind: "vendor")
      select "PwC", from: "Organisation"
      click_button "Add Vendor"

      expect(page).to have_selector("[data-testid='field-error']", text: "is already a Vendor on this Assignment")
    end

    it "Hides the panel from other users and turns them away from the forms" do
      assignment.update!(classification: "unrestricted")
      create(:dossier_assignment_partner, assignment: assignment, organisation: pwc)
      sign_in_as(create(:user, :content_creator))
      visit dossier_assignment_path(assignment)

      expect(page).not_to have_selector("[data-testid='assignment-partners']")
      expect(page).not_to have_text("PwC")
      visit new_dossier_assignment_partner_path(assignment, kind: "vendor")
      expect(page).to have_current_path(dossier_engagements_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows an Admin the Vendors and Customers" do
      create(:dossier_assignment_partner, :customer, assignment: assignment, organisation: telstra)
      sign_in_as(create(:user, :admin))
      visit dossier_assignment_path(assignment)

      expect(panel.find("[data-testid='customers']")).to have_link("Telstra")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Treats an unknown kind as a Vendor" do
      sign_in_as(charlie)
      visit new_dossier_assignment_partner_path(assignment, kind: "supplier")

      expect(page).to have_selector("h1.page-title", text: "Add A Vendor")
    end

    it "Shows empty states for both lists" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      expect(panel).to have_text("No Vendors yet.")
      expect(panel).to have_text("No Customers yet.")
    end
  end
end
