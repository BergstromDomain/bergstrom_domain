# spec/features/dossier/achievement_star_spec.rb
require "rails_helper"

# Achievements in STAR form (Situation, Task, Achievement as the Action,
# Impact as the Result), their rows showing Tech and Soft Skills, and the
# Assignment's Tech Stack kept in step: saving an Achievement adds its Tech
# Skills to the Stack, and saving an Assignment warns about Stack Skills no
# Achievement names.
RSpec.describe "Dossier Achievements in STAR form", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:uno)     { create(:user) }

  let!(:leadership)    { create(:dossier_skill, name: "Leadership", skill_category: create(:dossier_skill_category, name: "Soft Skills", soft: true)) }
  let!(:testing)       { create(:dossier_skill_category, name: "Testing", position: 1) }
  let!(:methods)       { create(:dossier_skill_category, name: "Methods & Processes", position: 2) }
  let!(:provar)        { create(:dossier_skill, name: "Provar", skill_category: testing) }
  let!(:azure_devops)  { create(:dossier_skill, name: "Azure DevOps", skill_category: testing) }
  let!(:test_strategy) { create(:dossier_skill, name: "Test Strategy", skill_category: methods) }

  let(:engagement) { create(:dossier_engagement, user: charlie, start_month: "2020-01", end_month: "2021-12") }
  let(:assignment) do
    create(:dossier_assignment, engagement: engagement, start_month: "2020-01", end_month: "2021-12",
                                test_tools_na: false, test_tools_text: "Provar")
  end

  def achievement(**attributes)
    create(:dossier_achievement, assignment: assignment, text: "Wrote the project's test strategy", **attributes)
  end

  def make_public(record)
    [ record, assignment, engagement ].each { |item| item.update!(classification: "unrestricted") }
  end

  def row = find("[data-testid='achievement-row']")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows each Achievement's Tech Skills and Soft Skills on its row, linking to them" do
      achievement(impact: "Signed off by all three teams", skills_text: "Provar", soft_skill_ids: [ leadership.id ])
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      expect(row.find("[data-testid='achievement-row-tech-skills']")).to have_text("Tech Skills: Provar")
      expect(row).to have_link("Provar", href: dossier_skill_path(provar))
      expect(row.find("[data-testid='achievement-row-skills']")).to have_text("Soft Skills: Leadership")
      expect(row.text).to match(/Impact:.*Tech Skills:.*Soft Skills:/m)
    end

    it "Adds a new Tech Skill to the Assignment's Tech Stack when saving an Achievement, with a toast" do
      sign_in_as(charlie)
      visit new_dossier_achievement_path(assignment_id: assignment.id)
      fill_in "Achievement", with: "Wrote the project's test strategy"
      fill_in "Technical Skills", with: "Test Strategy, Provar"
      click_button "Create Achievement"

      expect(page).to have_css("[data-testid='flash-tech_stack']", text: "Added Test Strategy to the Tech Stack")
      expect(find("[data-testid='tech-stack']")).to have_link("Test Strategy")
      expect(assignment.reload.skills_in(:methodology)).to eq([ test_strategy ])
    end

    it "Warns, on saving an Assignment, about Tech Stack Skills no Achievement names" do
      assignment.update!(test_tools_text: "Provar, Azure DevOps")
      achievement(skills_text: "Provar")
      sign_in_as(charlie)
      visit edit_dossier_assignment_path(assignment)
      click_button "Update Assignment"

      expect(page).to have_css("[data-testid='flash-success']")
      expect(page).to have_css("[data-testid='flash-warning']", text: "Not in any Achievement: Azure DevOps")
    end

    it "Saves a Task, and shows Situation, Task, Achievement and Impact in that order" do
      sign_in_as(charlie)
      visit new_dossier_achievement_path(assignment_id: assignment.id)
      expect(all("label").map(&:text).grep(/\A(Situation|Task|Achievement|Impact)/))
        .to eq([ "Situation", "Task", "Achievement", "Impact" ])
      fill_in "Situation", with: "Three teams, no agreed test approach"
      fill_in "Task", with: "Define one approach every team signs up to"
      fill_in "Achievement", with: "Wrote the project's test strategy"
      fill_in "Impact", with: "Signed off by all three teams"
      click_button "Create Achievement"
      click_link "Wrote the project's test strategy"

      expect(page).to have_selector("[data-testid='achievement-task']", text: "Define one approach every team signs up to")
      expect(page.text).to match(/Situation.*Three teams.*Task.*Define one approach.*Wrote the project's test strategy.*Signed off/m)
    end

    it "Marks a row with a saved Situation or Task, without showing their text" do
      achievement(situation: "Three teams, no agreed test approach", task: "Define one approach")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      marker = row.find("[data-testid='achievement-row-star']")
      expect(marker[:title]).to eq("Situation and Task saved, on the Achievement's page")
      expect(row).to have_no_text("Three teams")
      expect(row).to have_no_text("Define one approach")
    end

    it "Keeps the scroll position when moving an Achievement", js: true do
      %w[First Second Third Fourth Fifth Sixth Seventh Eighth].each { |text| create(:dossier_achievement, assignment: assignment, text: text) }
      sign_in_and_settle(charlie)
      visit dossier_assignment_path(assignment)
      # The page scrolls inside .site-main, not the window. The button goes in
      # view first, as Selenium would scroll to it to click.
      scroll_top = "document.querySelector('.site-main').scrollTop"
      down = all("[data-testid='achievement-move-down']", minimum: 7)[5]
      page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", down)
      before = page.evaluate_script(scroll_top)
      expect(before).to be > 0

      down.click

      expect(page).to have_css("[data-testid='achievement-row']:nth-child(7) [data-testid='achievement-link']", text: "Sixth")
      expect(page.evaluate_script(scroll_top)).to be_within(5).of(before)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Doesn't warn when every Tech Stack Skill is named in an Achievement" do
      achievement(skills_text: "Provar")
      sign_in_as(charlie)
      visit edit_dossier_assignment_path(assignment)
      click_button "Update Assignment"

      expect(page).to have_css("[data-testid='flash-success']")
      expect(page).not_to have_css("[data-testid='flash-warning']")
    end

    it "Shows Chris and Uno no Task or marker on Charlie's Unrestricted Achievement, and Gary nothing" do
      record = achievement(situation: "Three teams", task: "Define one approach")
      make_public(record)

      [ chris, uno ].each do |user|
        sign_in_as(user)
        visit dossier_assignment_path(assignment)
        expect(row).not_to have_selector("[data-testid='achievement-row-star']")
        visit dossier_achievement_path(record)
        expect(page).to have_selector("[data-testid='achievement-text']")
        expect(page).not_to have_selector("[data-testid='achievement-task']")
        Capybara.reset_session!
      end

      # Gary can't open Dossier pages at all.
      visit dossier_achievement_path(record)
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows neither label for an Achievement with no Skills, and only Tech Skills when it has no Soft ones" do
      achievement(skills_text: "")
      create(:dossier_achievement, assignment: assignment, text: "Ran UAT", skills_text: "Provar")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      bare, tech = all("[data-testid='achievement-row']")
      expect(bare).not_to have_selector("[data-testid='achievement-row-tech-skills']")
      expect(bare).not_to have_selector("[data-testid='achievement-row-skills']")
      expect(tech).to have_selector("[data-testid='achievement-row-tech-skills']")
      expect(tech).not_to have_selector("[data-testid='achievement-row-skills']")
    end

    it "Names only the Situation in the marker when there's no Task" do
      achievement(situation: "Three teams")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      expect(row.find("[data-testid='achievement-row-star']")[:title]).to eq("Situation saved, on the Achievement's page")
    end
  end
end
