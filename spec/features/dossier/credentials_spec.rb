# spec/features/dossier/credentials_spec.rb
require "rails_helper"

RSpec.describe "Dossier Credentials", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:uno)     { create(:user) }

  let!(:degree)        { create(:dossier_credential_type, name: "Degree", position: 1) }
  let!(:certification) { create(:dossier_credential_type, name: "Certification", position: 3) }
  let!(:course)        { create(:dossier_credential_type, :training, name: "Course", position: 4) }
  let!(:linkedin)   { create(:dossier_organisation, name: "LinkedIn Learning") }
  let!(:apa)        { create(:dossier_organisation, name: "APA Group", abbreviation: "APA") }
  let!(:engagement) do
    create(:dossier_engagement, user: charlie, position_title: "Test Analyst", start_month: "2019-01", end_month: "2020-12")
  end
  let!(:assignment) do
    create(:dossier_assignment, engagement: engagement, client: apa, project: "Market Services",
                                start_month: "2019-01", end_month: "2020-12")
  end

  def fill_dates(start_year, start_month, end_year, end_month)
    fill_in "Started Year", with: start_year
    select start_month, from: "Started Month"
    fill_in "Completed Year", with: end_year
    select end_month, from: "Completed Month"
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds Training from an Assignment page and lists it there, on its Engagement and under My Career" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      within("[data-testid='show-panel-actions']") { click_link "Add Training" }

      expect(page).to have_select("Assignment", selected: "APA - Market Services (Jan 2019 – Dec 2020)")
      expect(page).to have_select("Type", selected: "Course")
      fill_in "Title", with: "Excel VBA Essential Training"
      select "LinkedIn Learning", from: "Issued By"
      fill_dates("2019", "May", "2019", "May")
      fill_in "Hours", with: "2.5"
      fill_in "Skills", with: "Excel VBA, Jira"
      click_button "Add Credential"

      expect(page).to have_current_path(dossier_assignment_path(assignment))
      expect(page).to have_css("[data-testid='flash-success']", text: "Excel VBA Essential Training has been successfully created")
      within("[data-testid='training-panel']") do
        expect(page).to have_selector("[data-testid='training-row']", text: "Excel VBA Essential Training · LinkedIn Learning")
        expect(page).to have_selector("[data-testid='training-row']", text: "May 2019")
      end

      visit dossier_engagement_path(engagement)
      expect(page).to have_selector("[data-testid='training-panel']", text: "Excel VBA Essential Training")

      visit dossier_credentials_path
      row = find("[data-testid='credential-row']")
      expect(row).to have_text("LinkedIn Learning")
      expect(row.find("[data-testid='credential-taken-during']")).to have_link("APA - Market Services")
      click_link "Excel VBA Essential Training"
      expect(page).to have_selector("[data-testid='credential-type']", text: "Course")
      expect(page).to have_selector("[data-testid='credential-hours']", text: "2.5")
      expect(page).to have_selector("[data-testid='credential-skills']", text: "Excel VBA, Jira")
    end

    it "Adds a Certification with an expiry, a Credential ID and a verification link" do
      sign_in_as(charlie)
      visit new_dossier_credential_path
      select "Certification", from: "Type"
      fill_in "Title", with: "ISTQB Foundation Certificate in Software Testing"
      fill_dates("2009", "August", "2009", "August")
      fill_in "Expires Year", with: "2030"
      select "June", from: "Expires Month"
      fill_in "Credential ID", with: "SSTBFCE-176004"
      fill_in "Verification URL", with: "https://example.com/verify/176004"
      click_button "Add Credential"

      expect(page).to have_current_path(dossier_credentials_path)
      click_link "ISTQB Foundation Certificate in Software Testing"
      expect(page).to have_selector("[data-testid='credential-type']", text: "Certification")
      expect(page).to have_selector("[data-testid='credential-expires']", text: "Jun 2030")
      expect(page).to have_selector("[data-testid='credential-number']", text: "SSTBFCE-176004")
      expect(page).to have_link("https://example.com/verify/176004", href: "https://example.com/verify/176004")
    end

    it "Groups My Career › Credentials by type in sort order, newest first within each" do
      create(:dossier_credential, user: charlie, title: "Agile Fundamentals", start_month: "2020-03", end_month: "2020-03")
      create(:dossier_credential, user: charlie, title: "Scrum Basics", start_month: "2022-03", end_month: "2022-03")
      create(:dossier_credential, user: charlie, title: "MSc Engineering Physics", credential_type: degree,
                                  start_month: "1995-08", end_month: "2001-06")
      create(:dossier_credential, user: charlie, title: "Certified ScrumMaster", credential_type: certification)
      sign_in_as(charlie)
      visit dossier_credentials_path

      expect(page).to have_selector("h1.page-title", text: "Credentials")
      groups = all("[data-testid='credential-group']").map { |group| group.find("h2").text }
      expect(groups).to eq(%w[Degree Certification Course])
      within(all("[data-testid='credential-group']").last) do
        expect(all("[data-testid='credential-row']").map { |row| row.find("a", match: :first).text })
          .to eq([ "Scrum Basics", "Agile Fundamentals" ])
      end
    end

    it "Shows Training on a Skill page and in My Career › Skills, without adding years" do
      create(:dossier_credential, user: charlie, title: "Jira Essentials", engagement: engagement, skills_text: "Jira")
      sign_in_as(charlie)

      visit dossier_skill_path(Dossier::Skill.find_by!(name: "Jira"))
      expect(page).to have_selector("[data-testid='skill-experience-duration']", text: "—")
      expect(page).to have_selector("[data-testid='skill-experience-training']", text: "1")
      expect(page).to have_selector("[data-testid='skill-training']", text: "Jira Essentials")

      visit dossier_my_skills_path
      row = find("[data-testid='my-skill-row']", text: "Jira")
      expect(row).to have_selector("[data-testid='my-skill-training']", text: "1")
      expect(row).to have_selector("[data-testid='my-skill-years']", text: "—")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows the errors when the title and start are missing" do
      sign_in_as(charlie)
      visit new_dossier_credential_path
      click_button "Add Credential"

      expect(page).to have_content("can't be blank")
      expect(Dossier::Credential.count).to eq(0)
    end

    it "Shows the error for an expiry before the start" do
      sign_in_as(charlie)
      visit new_dossier_credential_path
      fill_in "Title", with: "Certified ScrumMaster"
      fill_dates("2010", "February", "2010", "February")
      fill_in "Expires Year", with: "2009"
      select "January", from: "Expires Month"
      click_button "Add Credential"

      expect(page).to have_content("must not be before the start")
      expect(Dossier::Credential.count).to eq(0)
    end

    it "Keeps another Content Creator off Charlie's Credentials and its Engagements" do
      course = create(:dossier_credential, user: charlie, title: "Agile Fundamentals")
      sign_in_as(chris)

      visit dossier_credential_path(course)
      expect(page).to have_current_path(dossier_credentials_path)
      expect(page).to have_selector("[data-testid='empty-state']")

      visit new_dossier_credential_path(engagement_id: engagement.id)
      expect(page).to have_select("Engagement", options: [ "None" ])
    end

    it "Keeps an App User off My Career › Credentials" do
      sign_in_as(uno)
      visit dossier_credentials_path
      expect(page).to have_current_path(dossier_path)
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Adds Training that stands alone, then links it to an Engagement" do
      sign_in_as(charlie)
      visit dossier_credentials_path
      within("[data-testid='empty-state']") { click_link "Add A Credential" }
      fill_in "Title", with: "Ruby on Rails Essential Training"
      fill_dates("2021", "March", "2021", "April")
      click_button "Add Credential"

      expect(page).to have_current_path(dossier_credentials_path)
      expect(find("[data-testid='credential-taken-during']")).to have_text("—")

      click_link "Ruby on Rails Essential Training"
      click_link "Edit Credential"
      select "Test Analyst at #{engagement.employer.name} (Jan 2019 – Dec 2020)", from: "Engagement"
      click_button "Update Credential"

      expect(page).to have_selector("[data-testid='credential-taken-during']", text: "Test Analyst at")
    end

    it "Leaves a Certification off the Training panel" do
      create(:dossier_credential, user: charlie, title: "Certified ScrumMaster", credential_type: certification,
                                  engagement: engagement)
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)

      expect(page).to have_selector("[data-testid='training-empty']")
    end

    it "Deletes a Credential" do
      course = create(:dossier_credential, user: charlie, title: "Agile Fundamentals", engagement: engagement)
      sign_in_as(charlie)
      visit dossier_credential_path(course)
      click_button "Delete Credential"

      expect(page).to have_current_path(dossier_engagement_path(engagement))
      expect(page).to have_css("[data-testid='flash-success']", text: "Agile Fundamentals has been successfully deleted")
      expect(page).to have_selector("[data-testid='training-empty']")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Hides Credentials under a deleted Engagement" do
      create(:dossier_credential, user: charlie, title: "Agile Fundamentals", engagement: engagement)
      engagement.soft_delete!
      sign_in_as(charlie)
      visit dossier_credentials_path

      expect(page).to have_selector("[data-testid='empty-state']")
    end
  end
end
