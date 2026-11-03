# spec/features/dossier/skill_experience_spec.rb
require "rails_helper"

RSpec.describe "Dossier Skill experience", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:uno)     { create(:user) }

  let!(:test_tools) { create(:dossier_skill_category, name: "Test Tools") }
  let!(:methods)    { create(:dossier_skill_category, name: "Methodologies") }
  let!(:jira)       { create(:dossier_skill, name: "Jira", skill_category: test_tools) }
  let!(:excel)      { create(:dossier_skill, name: "Excel", skill_category: test_tools) }
  let!(:scrum)      { create(:dossier_skill, name: "Scrum", skill_category: methods) }

  let!(:northwind) { create(:dossier_organisation, name: "Northwind Transport Authority", abbreviation: "NTA") }
  let!(:engagement) do
    create(:dossier_engagement, user: charlie, start_month: "2015-01", end_month: "2022-12")
  end
  let!(:ticketing) do
    create(:dossier_assignment, engagement: engagement, client: northwind, project: "Ticketing",
                                start_month: "2015-01", end_month: "2017-12",
                                test_tools_na: false, test_tools_text: "Jira, Excel",
                                other_tools_na: false, other_tools_text: "Excel")
  end
  let!(:rail) do
    create(:dossier_assignment, engagement: engagement, client: northwind, project: "Rail",
                                start_month: "2018-01", end_month: "2018-06",
                                methodologies_na: false, methodologies_text: "Scrum")
  end
  let!(:triage) { create(:dossier_achievement, assignment: rail, text: "Ran daily defect triage.", skills_text: "Jira") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows your experience, Assignments by Tech Stack list and tagged Achievements on a Skill page" do
      sign_in_as(charlie)
      visit dossier_skill_path(jira)

      within("[data-testid='skill-experience']") do
        expect(page).to have_selector("[data-testid='skill-experience-duration']", text: "3+ years")
        expect(page).to have_selector("[data-testid='skill-experience-last-used']", text: "Jun 2018")
        expect(page).to have_selector("[data-testid='skill-experience-assignments']", text: "2")
      end
      within("[data-testid='related-assignments']") do
        groups = all("[data-testid='skill-slot-group']").map { |g| [ g.find("h3").text, g.all("li a").map(&:text) ] }
        expect(groups).to eq([ [ "Test Tools", [ "NTA - Ticketing" ] ], [ "Tagged On Achievements", [ "NTA - Rail" ] ] ])
      end
      within("[data-testid='skill-achievements']") do
        expect(page).to have_link("Ran daily defect triage.", href: dossier_achievement_path(triage))
      end
    end

    it "Lists every Skill you've used on My Career › Skills, by category, most years first" do
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Skills", match: :first }

      expect(page).to have_current_path(dossier_my_skills_path)
      categories = all("[data-testid='my-skills-category']").map { |c| c.find("h2").text }
      expect(categories).to eq(%w[Methodologies Test\ Tools])
      within(all("[data-testid='my-skills-category']").last) do
        expect(all("[data-testid='my-skill-row'] td:first-child").map(&:text)).to eq(%w[Jira Excel])
        expect(find("[data-testid='my-skill-row']", text: "Jira")).to have_text("3+ years")
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows a visitor the Skill without anyone's experience" do
      visit dossier_skill_path(jira)

      expect(page).to have_selector("[data-testid='reference-data-name']", text: "Jira")
      expect(page).not_to have_selector("[data-testid='skill-experience']")
      expect(page).not_to have_selector("[data-testid='related-assignments']")
      expect(page).not_to have_selector("[data-testid='skill-achievements']")
    end

    it "Shows another Content Creator none of Charlie's experience" do
      sign_in_as(chris)
      visit dossier_skill_path(jira)
      expect(page).not_to have_selector("[data-testid='skill-experience']")

      visit dossier_my_skills_path
      expect(page).to have_selector("[data-testid='empty-state']")
    end

    it "Keeps an App User off My Career › Skills" do
      sign_in_as(uno)
      visit dossier_my_skills_path
      expect(page).to have_current_path(dossier_path)
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Collapses a Skill Category on My Career › Skills", js: true do
      sign_in_as(charlie)
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 10)
      visit dossier_my_skills_path

      category = "[data-testid='my-skills-category']:has([data-testid='my-skills-toggle-#{test_tools.id}'])"
      expect(page).to have_selector("#{category}[open] [data-testid='my-skill-row']", text: "Jira")
      js_click("my-skills-toggle-#{test_tools.id}")
      expect(page).to have_selector("#{category}:not([open])")
      expect(page).not_to have_selector("#{category} [data-testid='my-skill-row']")
    end

    it "Shows personal projects' years apart from professional ones" do
      hobby = create(:dossier_engagement, :personal, user: charlie, start_month: "2023-01", end_month: "2024-12")
      create(:dossier_assignment, engagement: hobby, client: northwind, project: "Hobby App",
                                  start_month: "2023-01", end_month: "2024-12",
                                  test_tools_na: false, test_tools_text: "Jira, Rails")
      sign_in_as(charlie)

      visit dossier_skill_path(jira)
      expect(page).to have_selector("[data-testid='skill-experience-duration']", text: "3+ years")
      expect(page).to have_selector("[data-testid='skill-experience-personal-duration']", text: "2+ years")

      visit dossier_my_skills_path
      rails = find("[data-testid='my-skill-row']", text: "Rails")
      expect(rails).to have_selector("[data-testid='my-skill-years']", text: "—")
      expect(rails).to have_selector("[data-testid='my-skill-personal']", text: "2+ years")
    end

    it "Lists an Assignment under both lists that use the Skill" do
      sign_in_as(charlie)
      visit dossier_skill_path(excel)

      headings = all("[data-testid='skill-slot-group'] h3").map(&:text)
      expect(headings).to eq([ "Test Tools", "Other Tools" ])
      expect(page).to have_selector("[data-testid='skill-experience-assignments']", text: "1")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves out a deleted Engagement's Skills" do
      engagement.soft_delete!
      sign_in_as(charlie)
      visit dossier_my_skills_path
      expect(page).to have_selector("[data-testid='empty-state']")
    end
  end
end
