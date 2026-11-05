# spec/features/dossier/training_spec.rb
require "rails_helper"

RSpec.describe "Dossier Training", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:uno)     { create(:user) }

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
      fill_in "Title", with: "Excel VBA Essential Training"
      select "LinkedIn Learning", from: "Provider"
      fill_dates("2019", "May", "2019", "May")
      fill_in "Hours", with: "2.5"
      fill_in "Skills", with: "Excel VBA, Jira"
      click_button "Add Training"

      expect(page).to have_current_path(dossier_assignment_path(assignment))
      expect(page).to have_css("[data-testid='flash-success']", text: "Excel VBA Essential Training has been successfully created")
      within("[data-testid='training-panel']") do
        expect(page).to have_selector("[data-testid='training-row']", text: "Excel VBA Essential Training · LinkedIn Learning")
        expect(page).to have_selector("[data-testid='training-row']", text: "May 2019")
      end

      visit dossier_engagement_path(engagement)
      expect(page).to have_selector("[data-testid='training-panel']", text: "Excel VBA Essential Training")

      visit dossier_credentials_path
      row = find("[data-testid='training-row']")
      expect(row).to have_text("LinkedIn Learning")
      expect(row.find("[data-testid='training-taken-during']")).to have_link("APA - Market Services")
      click_link "Excel VBA Essential Training"
      expect(page).to have_selector("[data-testid='training-hours']", text: "2.5")
      expect(page).to have_selector("[data-testid='training-skills']", text: "Excel VBA, Jira")
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
      click_button "Add Training"

      expect(page).to have_content("can't be blank")
      expect(Dossier::Credential.count).to eq(0)
    end

    it "Keeps another Content Creator off Charlie's Training and its Engagements" do
      course = create(:dossier_credential, user: charlie, title: "Agile Fundamentals")
      sign_in_as(chris)

      visit dossier_credential_path(course)
      expect(page).to have_current_path(dossier_credentials_path)
      expect(page).to have_selector("[data-testid='empty-state']")

      visit new_dossier_credential_path(engagement_id: engagement.id)
      expect(page).to have_select("Engagement", options: [ "None" ])
    end

    it "Keeps an App User off My Career › Training" do
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
      within("[data-testid='empty-state']") { click_link "Add Training" }
      fill_in "Title", with: "Ruby on Rails Essential Training"
      fill_dates("2021", "March", "2021", "April")
      click_button "Add Training"

      expect(page).to have_current_path(dossier_credentials_path)
      expect(find("[data-testid='training-taken-during']")).to have_text("—")

      click_link "Ruby on Rails Essential Training"
      click_link "Edit Training"
      select "Test Analyst at #{engagement.employer.name} (Jan 2019 – Dec 2020)", from: "Engagement"
      click_button "Update Training"

      expect(page).to have_selector("[data-testid='training-taken-during']", text: "Test Analyst at")
    end

    it "Deletes Training" do
      course = create(:dossier_credential, user: charlie, title: "Agile Fundamentals", engagement: engagement)
      sign_in_as(charlie)
      visit dossier_credential_path(course)
      click_button "Delete Training"

      expect(page).to have_current_path(dossier_engagement_path(engagement))
      expect(page).to have_css("[data-testid='flash-success']", text: "Agile Fundamentals has been successfully deleted")
      expect(page).to have_selector("[data-testid='training-empty']")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Hides Training under a deleted Engagement" do
      create(:dossier_credential, user: charlie, title: "Agile Fundamentals", engagement: engagement)
      engagement.soft_delete!
      sign_in_as(charlie)
      visit dossier_credentials_path

      expect(page).to have_selector("[data-testid='empty-state']")
    end
  end
end
