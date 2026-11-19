# spec/features/dossier/engagements_spec.rb
require "rails_helper"

RSpec.describe "Dossier Engagements", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:uno)     { create(:user) }
  let(:admin)   { create(:user, :admin) }

  let!(:consultancy) { create(:dossier_organisation, name: "Consultancy A") }
  let!(:contractor)  { create(:dossier_employment_type, name: "Contractor") }
  let!(:permanent)   { create(:dossier_employment_type, :permanent, name: "Permanent Employment") }

  def fill_engagement(type: "Contractor", position: "Test Manager", start_month: "2019-03", end_month: "2022-06")
    select "Consultancy A", from: "Employer"
    select type, from: "Employment Type"
    fill_in "Position Title", with: position
    fill_in_dossier_month "Start", with: start_month
    fill_in_dossier_month "End", with: end_month
  end

  let(:career_break) { create(:dossier_employment_type, :career_break, name: "Career Break") }

  def time_off(**attributes)
    create(:dossier_engagement, :career_break, user: charlie, employment_type: career_break,
                                               start_month: "2012-10", end_month: "2013-04", **attributes)
  end

  def list_rows = all(".dossier-assignment-list > li").map { |row| row.find("a", match: :first).text }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates a career break with no Employer, headed by its Position Title" do
      career_break
      sign_in_as(charlie)
      visit new_dossier_engagement_path
      select "Career Break", from: "Employment Type"
      fill_in "Position Title", with: "Time off"
      fill_in_dossier_month "Start", with: "2012-10"
      fill_in_dossier_month "End", with: "2013-04"
      fill_in "Summary", with: "A year off: moved to Australia on a tourist visa."
      click_button "Create Engagement"

      expect(page).to have_css("[data-testid='flash-success']", text: "Time off has been successfully created")
      expect(page).to have_selector("h1.page-title", exact_text: "Time off")
      expect(page).to have_selector("[data-testid='engagement-employer']", exact_text: "None")
      expect(page).to have_selector("[data-testid='engagement-summary']", text: "moved to Australia")
    end

    it "Shows Gap - Other Engagements between a split Engagement's Assignments, linking them" do
      contract = create(:dossier_engagement, user: charlie, employer: consultancy, start_month: "2018-11", end_month: "2023-01")
      create(:dossier_assignment, engagement: contract, project: "EIP", start_month: "2018-11", end_month: "2019-08")
      create(:dossier_assignment, engagement: contract, project: "TMR", start_month: "2020-09", end_month: "2023-01")
      hudson = create(:dossier_engagement, user: charlie, employer: create(:dossier_organisation, name: "Hudson"),
                                           start_month: "2019-12", end_month: "2020-09")
      sign_in_as(charlie)
      visit dossier_engagement_path(contract)

      within("[data-testid='engagement-assignments']") do
        expect(list_rows).to eq([ "#{contract.assignments.first.heading}", "Hudson", "#{contract.assignments.last.heading}" ])
        within("[data-testid='engagement-other-engagements']") do
          expect(page).to have_text("Gap - Other Engagements · 1+ year: Hudson")
          expect(page).to have_selector(".dossier-assignment-row__dates", exact_text: "Sep 2019 – Aug 2020")
          expect(page).to have_link("Hudson", href: dossier_engagement_path(hudson))
        end
      end
    end

    it "Lets a Content Creator create an Engagement, with a toast" do
      sign_in_as(charlie)
      visit new_dossier_engagement_path
      fill_engagement
      click_button "Create Engagement"

      expect(page).to have_selector("h1.page-title", exact_text: "Consultancy A")
      expect(page).to have_css("[data-testid='flash-success']", text: "Test Manager at Consultancy A has been successfully created")
      expect(page).to have_selector("[data-testid='engagement-dates']", text: "Mar 2019 – Jun 2022")
    end

    it "Gives a permanent job its Assignment, shown on the Engagement" do
      sign_in_as(charlie)
      visit new_dossier_engagement_path
      fill_engagement(type: "Permanent Employment")
      click_button "Create Engagement"

      within("[data-testid='engagement-assignments']") do
        expect(page).to have_selector("[data-testid='assignment-row']", count: 1)
        expect(page).to have_link(exact_text: "Consultancy A - Test Manager")
      end
    end

    it "Lists the user's Engagements newest first on the Timeline, each titled by its organisation" do
      create(:dossier_engagement, user: charlie, employer: create(:dossier_organisation, name: "Older Org"),
                                  position_title: "Test Analyst", start_month: "2010-01", end_month: "2012-01")
      create(:dossier_engagement, user: charlie, employer: create(:dossier_organisation, name: "Elysium Digital"),
                                  position_title: "Test Manager", start_month: "2015-01", end_month: "2018-01")
      sign_in_as(charlie)
      visit dossier_engagements_path

      titles = all("[data-testid='engagement-title'] a.data-table__name-link").map(&:text)
      expect(titles).to eq([ "Elysium Digital", "Older Org" ])
      expect(page).to have_no_text("Test Manager at Elysium Digital")
    end

    it "Titles the Engagement page by its organisation, the Position Title in its details" do
      engagement = create(:dossier_engagement, user: charlie, employer: create(:dossier_organisation, name: "Elysium Digital"),
                                               position_title: "Test Manager")
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)

      expect(page).to have_selector("h1.page-title", exact_text: "Elysium Digital")
      expect(page).to have_text("Test Manager")
    end

    it "Updates an Engagement, with a toast" do
      engagement = create(:dossier_engagement, user: charlie, position_title: "Test Lead", employer: consultancy)
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)
      click_link "Edit Engagement"
      fill_in "Position Title", with: "Test Manager"
      click_button "Update Engagement"

      expect(page).to have_css("[data-testid='flash-success']", text: "Test Manager at Consultancy A has been successfully updated")
    end

    it "Deletes an Engagement, which leaves the Timeline" do
      engagement = create(:dossier_engagement, user: charlie, position_title: "Test Lead", employer: consultancy)
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)
      click_button "Delete Engagement"

      expect(page).to have_current_path(dossier_engagements_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Test Lead at Consultancy A has been successfully deleted")
      expect(page).not_to have_selector("[data-testid='engagement-title']")
      expect(engagement.reload.deleted_at).to be_present
    end

    it "Restores a deleted Engagement from Deleted Engagements, with its Assignments" do
      engagement = create(:dossier_engagement, user: charlie, position_title: "Test Lead", employer: consultancy)
      assignment = create(:dossier_assignment, engagement: engagement)
      engagement.soft_delete!
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Deleted Engagements" }

      within("[data-testid='deleted-engagement-row']") do
        expect(page).to have_selector("[data-testid='deleted-engagement-label']", text: "Test Lead at Consultancy A")
        expect(page).to have_selector("[data-testid='deleted-engagement-days-remaining']", text: "30")
        find("[data-testid='restore-engagement-#{engagement.id}']").click
      end

      expect(page).to have_css("[data-testid='flash-success']", text: "Test Lead at Consultancy A has been successfully restored")
      expect(page).to have_selector("[data-testid='empty-state']")
      visit dossier_assignment_path(assignment)
      expect(page).to have_current_path(dossier_assignment_path(assignment))
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Requires an Employer for every type but a career break" do
      sign_in_as(charlie)
      visit new_dossier_engagement_path
      select "Contractor", from: "Employment Type"
      fill_in "Position Title", with: "Test Manager"
      fill_in_dossier_month "Start", with: "2019-03"
      click_button "Create Engagement"

      expect(page).to have_text("Employer must exist")
    end

    it "Offers a career break no Assignments: no Add Assignment button, not in the Assignment form" do
      time_off
      sign_in_as(charlie)
      visit dossier_engagement_path(Dossier::Engagement.last)

      expect(page).to have_no_selector("[data-testid='engagement-assignments']")
      expect(page).to have_no_selector("[data-testid='add-assignment']")
      expect(page).to have_link("Edit Engagement")
      visit new_dossier_assignment_path
      expect(page).to have_no_select("Engagement", with_options: [ "Time off" ])
    end

    it "Shows errors for a missing position and an end before the start" do
      sign_in_as(charlie)
      visit new_dossier_engagement_path
      fill_engagement(position: "", start_month: "2019-03", end_month: "2019-01")
      click_button "Create Engagement"

      expect(page).to have_content("Position title can't be blank")
      expect(page).to have_content("End month must not be before the start")
      expect(Dossier::Engagement.count).to eq(0)
    end

    it "Sends 'Gary Guest' to the 'Sign in' page" do
      visit dossier_engagements_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Sends 'Uno User' back to the Dossier landing page" do
      sign_in_as(uno)
      visit new_dossier_engagement_path
      expect(page).to have_current_path(dossier_path)
    end

    it "Hides another Content Creator's Engagement" do
      engagement = create(:dossier_engagement, user: chris)
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)
      expect(page).to have_current_path(dossier_engagements_path)

      visit dossier_engagements_path
      expect(page).not_to have_selector("[data-testid='engagement-title']")
    end
  end

  describe "Negative Path (deleted)" do
    it "Hides a deleted Engagement's Assignments and Achievements from their owner" do
      engagement = create(:dossier_engagement, user: charlie)
      assignment = create(:dossier_assignment, engagement: engagement)
      achievement = create(:dossier_achievement, assignment: assignment)
      engagement.soft_delete!
      sign_in_as(charlie)

      visit dossier_assignment_path(assignment)
      expect(page).to have_current_path(dossier_engagements_path)
      visit dossier_achievement_path(achievement)
      expect(page).to have_current_path(dossier_engagements_path)
    end

    it "Lists and restores only your own deleted Engagements" do
      engagement = create(:dossier_engagement, user: charlie, position_title: "Test Lead", employer: consultancy)
      engagement.soft_delete!
      sign_in_as(chris)
      visit deleted_dossier_engagements_path
      expect(page).to have_selector("[data-testid='empty-state']")

      page.driver.submit :post, restore_dossier_engagement_path(engagement), {}
      expect(engagement.reload.deleted_at).to be_present
    end

    it "Leaves a deleted Engagement's deleted Achievements off Deleted Achievements" do
      engagement = create(:dossier_engagement, user: charlie)
      create(:dossier_achievement, assignment: create(:dossier_assignment, engagement: engagement), text: "Hidden bullet.")
        .soft_delete!
      engagement.soft_delete!
      sign_in_as(charlie)
      visit deleted_dossier_achievements_path
      expect(page).not_to have_content("Hidden bullet.")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lists the Contributions made during the Engagement, newest first, with their kind" do
      engagement = create(:dossier_engagement, user: charlie, employer: consultancy, classification: "unrestricted")
      create(:dossier_contribution, user: charlie, engagement: engagement, title: "Statistical Methods", start_year: 2023,
                                    start_month_number: 4, start_day: 19, event: create(:dossier_organisation, name: "All Things Testing"))
      create(:dossier_contribution, user: charlie, engagement: engagement, kind: "article", title: "Robot Framework Tips",
                                    start_year: 2024, start_month_number: 11)
      create(:dossier_contribution, user: charlie, title: "Not During It")
      create(:dossier_contribution, user: charlie, engagement: engagement, title: "Deleted Talk").soft_delete!
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)

      within("[data-testid='engagement-contributions']") do
        rows = all("[data-testid='engagement-contribution-row']")
        expect(rows.map { |row| row.find("[data-testid='contribution-title']").text })
          .to eq([ "Robot Framework Tips", "Statistical Methods" ])
        expect(rows.last).to have_text("Talk").and have_link("All Things Testing").and have_text("19 Apr 2023")
        expect(rows.first).to have_text("Article")
      end
    end

    it "Shows another user only the Contributions they may read on an Engagement they can see" do
      engagement = create(:dossier_engagement, user: charlie, employer: consultancy, classification: "unrestricted")
      create(:dossier_contribution, user: charlie, engagement: engagement, title: "Open Talk", classification: "unrestricted")
      create(:dossier_contribution, user: charlie, engagement: engagement, title: "Private Talk", classification: "restricted")
      sign_in_as(chris)
      visit dossier_engagement_path(engagement)

      within("[data-testid='engagement-contributions']") do
        expect(page).to have_link("Open Talk")
        expect(page).to have_no_text("Private Talk")
      end
    end

    it "Shows a permanent job's bench time between the Assignments either side of it, as on the Timeline" do
      engagement = create(:dossier_engagement, user: charlie, employer: consultancy, employment_type: permanent,
                                               start_month: "2019-01", end_month: "2019-12")
      engagement.assignments.sole.update!(start_month: "2019-01", end_month: "2019-06")
      create(:dossier_assignment, engagement: engagement, client: consultancy, start_month: "2019-08", end_month: "2019-12")
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)

      within("[data-testid='engagement-assignments']") do
        rows = all("[data-testid='assignment-row'], [data-testid='timeline-bench']")
        expect(rows.map { |row| row["data-testid"] }).to eq(%w[assignment-row timeline-bench assignment-row])
        expect(page).to have_link("Bench · 1 month")
        expect(page).to have_selector("[data-testid='timeline-bench']", text: "Jul 2019")
      end
    end

    it "Shows no bench time on a Contractor's Engagement between its Assignments" do
      engagement = create(:dossier_engagement, user: charlie, employer: consultancy, start_month: "2019-01", end_month: "2019-12")
      create(:dossier_assignment, engagement: engagement, client: consultancy, start_month: "2019-01", end_month: "2019-06")
      create(:dossier_assignment, engagement: engagement, client: consultancy, start_month: "2019-08", end_month: "2019-12")
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)

      expect(page).to have_selector("[data-testid='assignment-row']", count: 2)
      expect(page).to have_no_selector("[data-testid='timeline-bench']")
    end

    it "Takes an exact start day and no end for a current job" do
      sign_in_as(charlie)
      visit new_dossier_engagement_path
      fill_engagement(end_month: "")
      fill_in "Start Day", with: "15"
      click_button "Create Engagement"

      expect(page).to have_selector("[data-testid='engagement-dates']", text: "15 Mar 2019 – Present")
    end

    it "Takes the month from a list, so a year and \"May\" make a valid date" do
      sign_in_as(charlie)
      visit new_dossier_engagement_path
      fill_engagement(end_month: "")
      fill_in "Start Year", with: "2019"
      select "May", from: "Start Month"
      click_button "Create Engagement"

      expect(page).to have_selector("[data-testid='engagement-dates']", text: "May 2019 – Present")
    end

    it "Links an Admin to Add An Employment Type" do
      sign_in_as(admin)
      visit new_dossier_engagement_path
      expect(page).to have_link("Add An Employment Type", href: new_dossier_employment_type_path)
    end

    it "Asks a Content Creator to ask an Admin for a missing Employment Type" do
      sign_in_as(charlie)
      visit new_dossier_engagement_path
      expect(page).not_to have_link("Add An Employment Type")
      expect(page).to have_content("Not listed? Ask an Admin to add it.")
    end

    it "Lets an admin read another user's Engagement" do
      engagement = create(:dossier_engagement, user: chris, position_title: "Test Lead", employer: consultancy)
      sign_in_as(admin)
      visit dossier_engagement_path(engagement)
      expect(page).to have_selector("h1.page-title", exact_text: "Consultancy A")
      expect(page).to have_text("Test Lead")
    end

    it "Is reachable from the left nav" do
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Create An Engagement" }
      expect(page).to have_current_path(new_dossier_engagement_path)
      within("[data-testid='left-nav']") { click_link "Timeline" }
      expect(page).to have_current_path(dossier_engagements_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Places a bench at the bottom when no Assignment ended before it" do
      engagement = create(:dossier_engagement, user: charlie, employer: consultancy, employment_type: permanent,
                                               start_month: "2019-01", end_month: "2019-12")
      engagement.assignments.sole.update!(start_month: "2019-04", end_month: "2019-12")
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)

      within("[data-testid='engagement-assignments']") { expect(list_rows.last).to eq("Bench · 3 months") }
    end

    it "Places two benches each between its own neighbours" do
      engagement = create(:dossier_engagement, user: charlie, employer: consultancy, employment_type: permanent,
                                               start_month: "2019-01", end_month: "2019-12")
      engagement.assignments.sole.update!(start_month: "2019-01", end_month: "2019-03", project: "One")
      create(:dossier_assignment, engagement: engagement, client: consultancy, project: "Two", start_month: "2019-05", end_month: "2019-07")
      create(:dossier_assignment, engagement: engagement, client: consultancy, project: "Three", start_month: "2019-10", end_month: "2019-12")
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)

      within("[data-testid='engagement-assignments']") do
        expect(list_rows).to eq([ "Consultancy A - Three", "Bench · 2 months", "Consultancy A - Two", "Bench · 1 month", "Consultancy A - One" ])
      end
    end

    it "Orders a bench by date when the Assignments are ordered oldest first by hand" do
      engagement = create(:dossier_engagement, user: charlie, employer: consultancy, employment_type: permanent,
                                               start_month: "2019-01", end_month: "2019-12")
      first = engagement.assignments.sole
      first.update!(start_month: "2019-01", end_month: "2019-03", project: "One")
      create(:dossier_assignment, engagement: engagement, client: consultancy, project: "Two", start_month: "2019-06", end_month: "2019-12")
      first.update!(position: -5)
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)

      within("[data-testid='engagement-assignments']") do
        expect(list_rows).to eq([ "Bench · 2 months", "Consultancy A - One", "Consultancy A - Two" ])
      end
    end

    it "Deletes and restores a career break without an Employer" do
      engagement = time_off
      sign_in_as(charlie)
      visit dossier_employment_type_path(career_break)
      expect(page).to have_selector("[data-testid='your-engagement-title']", exact_text: "Time off")

      visit dossier_engagement_path(engagement)
      click_button "Delete Engagement"
      expect(page).to have_css("[data-testid='flash-success']", text: "Time off has been successfully deleted")
      visit deleted_dossier_engagements_path
      expect(page).to have_text("Time off")
      click_button "Restore"

      visit dossier_engagements_path
      expect(page).to have_selector("[data-testid='engagement-career-break']")
    end

    it "Says so when no Contributions were made during the Engagement" do
      engagement = create(:dossier_engagement, user: charlie, employer: consultancy)
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)

      within("[data-testid='engagement-contributions']") do
        expect(page).to have_selector("[data-testid='engagement-contributions-empty']", text: "No Contributions yet.")
        expect(page).to have_no_selector("[data-testid='engagement-contribution-row']")
      end
    end

    it "Shows an error for a year without a month" do
      sign_in_as(charlie)
      visit new_dossier_engagement_path
      fill_engagement(end_month: "")
      select "Choose a month", from: "Start Month"
      click_button "Create Engagement"

      expect(page).to have_content("Start month needs a four-digit year and a month, e.g. 2019 and May")
    end

    it "Shows an error for a day that isn't in the month" do
      sign_in_as(charlie)
      visit new_dossier_engagement_path
      fill_engagement(start_month: "2019-02")
      fill_in "Start Day", with: "30"
      click_button "Create Engagement"

      expect(page).to have_content("Start day is not a day in that month")
    end

    it "Shows an empty Timeline with a prompt" do
      sign_in_as(charlie)
      visit dossier_engagements_path
      expect(page).to have_selector("[data-testid='empty-state']")
    end
  end
end
