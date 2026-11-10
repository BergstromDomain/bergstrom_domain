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
    fill_in_dossier_month "Start", with: start_month
    fill_in_dossier_month "End", with: end_month
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

      expect(page).to have_selector("h1.page-title", exact_text: "Northwind Transport Authority - Ticketing Upgrade")
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
      fill_in_dossier_month "End", with: "2020-06"
      click_button "Update Assignment"
      expect(page).to have_selector("[data-testid='assignment-dates']", text: "Apr 2019 – Jun 2020")

      click_button "Delete Assignment"
      expect(page).to have_current_path(dossier_engagement_path(engagement))
      expect(page).to have_css("[data-testid='flash-success']", text: "Test Lead at Northwind Transport Authority has been successfully deleted")
      expect(page).to have_css("[data-testid='flash-info']",
        text: "You can restore it, with its Achievements, from Deleted Assignments for 30 days.")
      expect(assignment.reload.deleted_at).to be_present
    end

    it "Restores a deleted Assignment from Deleted Assignments, with its Achievements" do
      assignment  = create(:dossier_assignment, engagement: engagement, client: northwind, role: test_lead,
                                                start_month: "2019-04", end_month: "2020-01")
      achievement = create(:dossier_achievement, assignment: assignment, text: "Cut regression testing to one day")
      assignment.soft_delete!
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Deleted Assignments" }

      within("[data-testid='deleted-assignment-row']") do
        expect(page).to have_selector("[data-testid='deleted-assignment-label']", text: "Test Lead at Northwind Transport Authority")
        expect(page).to have_selector("[data-testid='deleted-assignment-engagement']", text: "Test Consultant at Consultancy A")
        expect(page).to have_selector("[data-testid='deleted-assignment-achievements']", text: "1")
        expect(page).to have_selector("[data-testid='deleted-assignment-days-remaining']", text: "30")
        find("[data-testid='restore-assignment-#{assignment.id}']").click
      end

      expect(page).to have_css("[data-testid='flash-success']",
        text: "Test Lead at Northwind Transport Authority has been successfully restored")
      expect(page).to have_selector("[data-testid='empty-state']")
      visit dossier_assignment_path(assignment)
      expect(page).to have_content(achievement.text)
    end

    it "Saves the Tech Stack and shows it, new Skills under Uncategorised" do
      create(:dossier_skill_category, name: "Uncategorised")
      sign_in_as(charlie)
      visit new_dossier_assignment_path(engagement_id: engagement.id)
      fill_assignment
      find("[data-testid='test-tools-na-field']").uncheck
      fill_in "Test Tools", with: "Jira, Robot Framework"
      click_button "Create Assignment"

      within("[data-testid='tech-stack']") do
        block = find("[data-testid='tech-stack-block']")
        expect(block.all("th").map(&:text)).to eq([ "Uncategorised" ])
        expect(block).to have_link("Jira")
        expect(block).to have_link("Robot Framework")
        # One flex item, so the cell's flex gap can't open a space before each comma.
        expect(block).to have_selector("td > span", exact_text: "Jira, Robot Framework")
      end
      within("[data-testid='assignment-systems-under-test']") { click_link "Ticketing platform" }
      expect(page).to have_selector("[data-testid='reference-data-name']", text: "Ticketing platform")
      expect(page).to have_selector("[data-testid='related-assignments']", text: "NTA")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Hides a deleted Assignment and its Achievements from the Timeline, Achievements and its own page" do
      assignment = create(:dossier_assignment, engagement: engagement, client: northwind, role: test_lead,
                                               project: "Ticketing Upgrade", start_month: "2019-04", end_month: "2020-01")
      create(:dossier_achievement, assignment: assignment, text: "Cut regression testing to one day")
      assignment.soft_delete!
      sign_in_as(charlie)

      visit dossier_engagements_path
      expect(page).not_to have_content("Ticketing Upgrade")
      visit dossier_engagement_path(engagement)
      expect(page).not_to have_content("Ticketing Upgrade")
      visit dossier_achievements_path
      expect(page).not_to have_content("Cut regression testing to one day")
      visit dossier_assignment_path(assignment)
      expect(page).to have_current_path(dossier_engagements_path)
    end

    it "Leaves a deleted Assignment out of Experience and the CV" do
      assignment = create(:dossier_assignment, engagement: engagement, client: northwind, role: test_lead,
                                               start_month: "2019-04", end_month: "2020-01")
      assignment.soft_delete!
      create(:dossier_profile, user: charlie)

      expect(Dossier::ExperienceCalculator.new(charlie).slice(:client).map(&:label)).not_to include(northwind.name)
      expect(Dossier::CvDocument.new(charlie).experience.flat_map(&:assignments)).to be_empty
    end

    it "Doesn't let anyone add Colleagues to a deleted Assignment" do
      assignment = create(:dossier_assignment, engagement: engagement)
      assignment.soft_delete!
      sign_in_as(charlie)

      visit new_dossier_assignment_colleague_path(assignment)
      expect(page).to have_current_path(dossier_engagements_path)
    end

    it "Doesn't let Chris see Charlie's Deleted Assignments" do
      create(:dossier_assignment, engagement: engagement, client: northwind, role: test_lead,
                                  start_month: "2019-04", end_month: "2020-01").soft_delete!
      sign_in_as(chris)
      visit deleted_dossier_assignments_path
      expect(page).to have_selector("[data-testid='empty-state']")
    end

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

      expect(page).to have_selector("h1.page-title", exact_text: "Northwind Transport Authority")
      expect(page).to have_selector("[data-testid='assignment-role']", text: "Test Lead")
    end

    it "Uses the position title when no Role is chosen" do
      sign_in_as(charlie)
      visit new_dossier_assignment_path(engagement_id: engagement.id)
      fill_assignment
      select "Same as position title", from: "Role"
      click_button "Create Assignment"

      expect(page).to have_selector("[data-testid='assignment-role']", text: "Test Consultant")
    end
    it "Links the Client, Role and Location to pages listing your Assignments with them" do
      assignment = create(:dossier_assignment, engagement: engagement, client: northwind, role: test_lead,
                                               location: brisbane, project: "Ticketing")
      create(:dossier_assignment, engagement: create(:dossier_engagement, user: chris), client: northwind,
                                  role: test_lead, location: brisbane, project: "Chris's Project")
      sign_in_as(charlie)

      { "Test Lead" => dossier_role_path(test_lead),
        "Northwind Transport Authority (NTA)" => dossier_organisation_path(northwind),
        "Brisbane, Australia" => dossier_location_path(brisbane) }.each do |link, path|
        visit dossier_assignment_path(assignment)
        click_link link
        expect(page).to have_current_path(path)
        within("[data-testid='related-assignments']") do
          expect(page).to have_link("NTA - Ticketing", href: dossier_assignment_path(assignment))
          expect(page).not_to have_content("Chris's Project")
        end
      end
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Won't restore an Assignment that no longer fits its Engagement's dates" do
      assignment = create(:dossier_assignment, engagement: engagement, client: northwind, role: test_lead,
                                               start_month: "2021-01", end_month: "2022-06")
      assignment.soft_delete!
      engagement.update!(end_month: "2020-06")
      sign_in_as(charlie)

      visit deleted_dossier_assignments_path
      find("[data-testid='restore-assignment-#{assignment.id}']").click
      expect(page).to have_css("[data-testid='flash-alert']",
        text: "Test Lead at Northwind Transport Authority no longer fits within its Engagement's dates")
      expect(assignment.reload.deleted_at).to be_present
    end

    it "Lists an Assignment whose Engagement is deleted under Deleted Engagements, not Deleted Assignments" do
      assignment = create(:dossier_assignment, engagement: engagement)
      assignment.soft_delete!
      engagement.soft_delete!
      sign_in_as(charlie)

      visit deleted_dossier_assignments_path
      expect(page).to have_selector("[data-testid='empty-state']")
    end

    it "Shows a Role used by no Assignment of yours without the list" do
      sign_in_as(charlie)
      visit dossier_role_path(test_lead)
      expect(page).not_to have_selector("[data-testid='related-assignments']")
    end

    it "Shows a visitor a Role without anyone's Assignments" do
      create(:dossier_assignment, engagement: engagement, client: northwind, role: test_lead)
      visit dossier_role_path(test_lead)
      expect(page).to have_selector("[data-testid='reference-data-name']", text: "Test Lead")
      expect(page).not_to have_selector("[data-testid='related-assignments']")
    end

    it "Leaves deleted Engagements out of the picker" do
      engagement.soft_delete!
      sign_in_as(charlie)
      visit new_dossier_assignment_path
      expect(page).not_to have_select("Engagement", with_options: [ engagement.to_toast_label ])
    end
  end
end
