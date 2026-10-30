# spec/features/dossier/assignments_spec.rb
require "rails_helper"

RSpec.describe "Dossier Assignments", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }

  let!(:consultancy) { create(:dossier_organisation, name: "Consultancy A") }
  let!(:northwind)   { create(:dossier_organisation, name: "Northwind Transport Authority", abbreviation: "NTA") }
  let!(:test_lead)   { create(:dossier_role, name: "Test Lead") }
  let!(:brisbane)    { create(:dossier_location, city: "Brisbane", country: "Australia") }
  let!(:engagement) do
    create(:dossier_engagement, user: charlie, employer: consultancy, position_title: "Test Consultant",
                                start_month: "2019-03", end_month: "2022-06")
  end

  def fill_assignment(start_month: "2019-04", end_month: "2020-01")
    select "Northwind Transport Authority", from: "Client"
    select "Test Lead", from: "Role"
    fill_in "Start Month", with: start_month
    fill_in "End Month", with: end_month
    fill_in "System Under Test", with: "Ticketing platform"
    %w[operating-systems methodologies test-tools other-tools protocols].each do |list|
      find("[data-testid='#{list}-na-field']").check
    end
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds an Assignment from its Engagement, with a toast" do
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)
      click_link "Add Assignment"
      fill_assignment
      select "Brisbane, Australia", from: "Location"
      check "Remote"
      fill_in "Project", with: "Ticketing Upgrade"
      click_button "Create Assignment"

      expect(page).to have_selector("h1.page-title", text: "Test Lead at Northwind Transport Authority")
      expect(page).to have_css("[data-testid='flash-success']", text: "Test Lead at Northwind Transport Authority has been successfully created")
      expect(page).to have_selector("[data-testid='assignment-client']", text: "Northwind Transport Authority (NTA)")
      expect(page).to have_selector("[data-testid='assignment-location']", text: "Brisbane, Australia (remote)")
      expect(page).to have_selector("[data-testid='assignment-project']", text: "Ticketing Upgrade")
    end

    it "Updates and deletes an Assignment" do
      assignment = create(:dossier_assignment, engagement: engagement, client: northwind, role: test_lead,
                                               start_month: "2019-04", end_month: "2020-01")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      click_link "Edit Assignment"
      fill_in "End Month", with: "2020-06"
      click_button "Update Assignment"
      expect(page).to have_selector("[data-testid='assignment-dates']", text: "Apr 2019 – Jun 2020")

      click_button "Delete Assignment"
      expect(page).to have_current_path(dossier_engagement_path(engagement))
      expect(page).to have_css("[data-testid='flash-success']", text: "Test Lead at Northwind Transport Authority has been successfully deleted")
    end

    it "Saves the Tech Stack and shows it, with N/A for empty lists" do
      create(:dossier_skill_category, name: "Uncategorised")
      sign_in_as(charlie)
      visit new_dossier_assignment_path(engagement_id: engagement.id)
      fill_assignment
      find("[data-testid='test-tools-na-field']").uncheck
      fill_in "Test Tools", with: "Jira, Robot Framework"
      click_button "Create Assignment"

      within("[data-testid='tech-stack']") do
        expect(page).to have_selector("[data-testid='tech-stack-system-under-test']", text: "Ticketing platform")
        expect(page).to have_link("Jira")
        expect(page).to have_link("Robot Framework")
        expect(page).to have_selector("[data-testid='tech-stack-protocols']", text: "N/A")
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error for a Tech Stack list that is neither filled nor N/A" do
      sign_in_as(charlie)
      visit new_dossier_assignment_path(engagement_id: engagement.id)
      fill_assignment
      find("[data-testid='protocols-na-field']").uncheck
      click_button "Create Assignment"

      expect(page).to have_content("Protocols needs at least one item, or tick N/A")
      expect(Dossier::Assignment.count).to eq(0)
    end

    it "Shows an error for dates outside the Engagement" do
      sign_in_as(charlie)
      visit new_dossier_assignment_path(engagement_id: engagement.id)
      fill_assignment(start_month: "2019-01")
      click_button "Create Assignment"

      expect(page).to have_content("Start month must not be before the Engagement starts (Mar 2019)")
      expect(Dossier::Assignment.count).to eq(0)
    end

    it "Won't add an Assignment to another user's Engagement" do
      sign_in_as(chris)
      visit new_dossier_assignment_path(engagement_id: engagement.id)
      expect(page).not_to have_select("Engagement", with_options: [ engagement.to_toast_label ])
    end

    it "Hides another Content Creator's Assignment" do
      assignment = create(:dossier_assignment, engagement: engagement)
      sign_in_as(chris)
      visit dossier_assignment_path(assignment)
      expect(page).to have_current_path(dossier_engagements_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Starts from the left nav with an Engagement picker" do
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Create An Assignment" }
      select "Test Consultant at Consultancy A", from: "Engagement"
      fill_assignment
      click_button "Create Assignment"

      expect(page).to have_selector("h1.page-title", text: "Test Lead at Northwind Transport Authority")
    end

    it "Uses the position title when no Role is chosen" do
      sign_in_as(charlie)
      visit new_dossier_assignment_path(engagement_id: engagement.id)
      fill_assignment
      select "Same as position title", from: "Role"
      click_button "Create Assignment"

      expect(page).to have_selector("h1.page-title", text: "Test Consultant at Northwind Transport Authority")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves deleted Engagements out of the picker" do
      engagement.soft_delete!
      sign_in_as(charlie)
      visit new_dossier_assignment_path
      expect(page).not_to have_select("Engagement", with_options: [ engagement.to_toast_label ])
    end
  end
end
