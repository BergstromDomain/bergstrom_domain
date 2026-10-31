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

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Lets a Content Creator create an Engagement, with a toast" do
      sign_in_as(charlie)
      visit new_dossier_engagement_path
      fill_engagement
      click_button "Create Engagement"

      expect(page).to have_selector("h1.page-title", text: "Test Manager at Consultancy A")
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
        expect(page).to have_link(exact_text: "Consultancy A")
      end
    end

    it "Lists the user's Engagements newest first on the Timeline" do
      create(:dossier_engagement, user: charlie, position_title: "Older", start_month: "2010-01", end_month: "2012-01")
      create(:dossier_engagement, user: charlie, position_title: "Newer", start_month: "2015-01", end_month: "2018-01")
      sign_in_as(charlie)
      visit dossier_engagements_path

      titles = all("[data-testid='engagement-title']").map(&:text)
      expect(titles.first).to include("Newer")
      expect(titles.last).to include("Older")
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
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
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

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows bench time among the Assignments, as on the Timeline" do
      engagement = create(:dossier_engagement, user: charlie, employer: consultancy, start_month: "2019-01", end_month: "2019-12")
      create(:dossier_assignment, engagement: engagement, client: consultancy, start_month: "2019-01", end_month: "2019-06")
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
      expect(page).to have_selector("h1.page-title", text: "Test Lead at Consultancy A")
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
