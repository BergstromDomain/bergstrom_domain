# spec/features/dossier/staff_members_spec.rb
require "rails_helper"

RSpec.describe "Dossier Vendor and Customer Staff", type: :feature do
  let(:charlie)    { create(:user, :content_creator) }
  let(:engagement) { create(:dossier_engagement, user: charlie) }
  let(:assignment) { create(:dossier_assignment, engagement: engagement) }
  let(:pwc)        { create(:dossier_organisation, name: "PwC") }
  let!(:vendor)    { create(:dossier_assignment_partner, assignment: assignment, organisation: pwc) }

  def vendor_box = find("[data-testid='vendors'] [data-testid='partner-row']")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds a Staff member to a Vendor and lists their details under it" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      within(vendor_box) { click_link "Add Staff" }

      expect(page).to have_selector("h1.page-title", text: "Add Staff Member")
      expect(page).to have_text("PwC (Vendor)")
      fill_in "Name", with: "Priya Patel"
      fill_in "Position", with: "Delivery Lead"
      fill_in "Mobile", with: "+61 400 111 222"
      fill_in "Email", with: "priya@pwc.example"
      fill_in "LinkedIn", with: "https://linkedin.com/in/priya"
      fill_in "Comment", with: "Owns the release plan"
      click_button "Add Staff Member"

      expect(page).to have_current_path(dossier_assignment_path(assignment))
      expect(page).to have_css("[data-testid='flash-success']", text: "Priya Patel has been successfully created")
      row = vendor_box.find("[data-testid='staff-row']")
      expect(row).to have_text("Delivery Lead")
      expect(row).to have_text("+61 400 111 222")
      expect(row).to have_link("priya@pwc.example", href: "mailto:priya@pwc.example")
      expect(row).to have_link("LinkedIn", href: "https://linkedin.com/in/priya")
      expect(row).to have_text("Owns the release plan")
    end

    it "Edits and deletes a Customer's Staff member" do
      customer = create(:dossier_assignment_partner, :customer, assignment: assignment,
                                                                organisation: create(:dossier_organisation, name: "Telstra"))
      create(:dossier_staff_member, assignment_partner: customer, name: "Tom")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      within("[data-testid='customers'] [data-testid='staff-row']") { click_link "Edit" }

      expect(page).to have_selector("h1.page-title", text: "Edit Staff Member")
      fill_in "Position", with: "Product Owner"
      click_button "Save Staff Member"
      expect(page).to have_css("[data-testid='customers'] [data-testid='staff-row']", text: "Product Owner")

      within("[data-testid='customers'] [data-testid='staff-row']") { click_button "Delete" }
      expect(page).to have_css("[data-testid='flash-success']", text: "Tom has been successfully deleted")
      expect(page).not_to have_css("[data-testid='staff-row']")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a name" do
      sign_in_as(charlie)
      visit new_dossier_assignment_partner_staff_member_path(assignment, vendor)
      click_button "Add Staff Member"

      expect(page).to have_selector("[data-testid='field-error']", text: "can't be blank")
    end

    it "Hides Staff from anyone but the owner and Admins, even on a public Assignment" do
      assignment.update!(classification: "unrestricted")
      create(:dossier_staff_member, assignment_partner: vendor, name: "Priya Patel")
      sign_in_as(create(:user, :content_creator))
      visit dossier_assignment_path(assignment)

      expect(page).to have_selector("[data-testid='show-panel-metadata']")
      expect(page).not_to have_text("Priya Patel")
    end

    it "Turns away another user from the Staff forms" do
      member = create(:dossier_staff_member, assignment_partner: vendor)
      sign_in_as(create(:user, :content_creator))

      visit new_dossier_assignment_partner_staff_member_path(assignment, vendor)
      expect(page).to have_current_path(dossier_engagements_path)
      visit edit_dossier_assignment_partner_staff_member_path(assignment, vendor, member)
      expect(page).to have_current_path(dossier_engagements_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows an Admin the Staff" do
      create(:dossier_staff_member, assignment_partner: vendor, name: "Priya Patel")
      sign_in_as(create(:user, :admin))
      visit dossier_assignment_path(assignment)

      expect(vendor_box).to have_css("[data-testid='staff-row']", text: "Priya Patel")
    end

    it "Says how many Staff go when their Vendor is removed" do
      create_list(:dossier_staff_member, 2, assignment_partner: vendor)
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      delete_button = vendor_box.find("form[action='#{dossier_assignment_partner_path(assignment, vendor)}'] button")
      expect(delete_button["data-turbo-confirm"]).to eq("Remove PwC as a Vendor? This also deletes its 2 Staff members.")
      delete_button.click
      expect(Dossier::StaffMember.count).to eq(0)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Won't edit a Staff member through another Vendor's or Assignment's URL" do
      other_vendor = create(:dossier_assignment_partner, assignment: assignment)
      member = create(:dossier_staff_member, assignment_partner: other_vendor)
      other_assignment = create(:dossier_assignment, engagement: engagement)
      sign_in_as(charlie)

      visit edit_dossier_assignment_partner_staff_member_path(assignment, vendor, member)
      expect(page).to have_http_status(:not_found)
      visit new_dossier_assignment_partner_staff_member_path(other_assignment, vendor)
      expect(page).to have_http_status(:not_found)
    end
  end
end
