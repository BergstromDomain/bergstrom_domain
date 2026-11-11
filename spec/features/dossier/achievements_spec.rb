# spec/features/dossier/achievements_spec.rb
require "rails_helper"

RSpec.describe "Dossier Achievements", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:uno)     { create(:user) }

  let!(:northwind) { create(:dossier_organisation, name: "Northwind Transport Authority", abbreviation: "NTA") }
  let!(:engagement) do
    create(:dossier_engagement, user: charlie, employer: northwind, position_title: "Test Manager",
                                start_month: "2019-03", end_month: "2022-06")
  end
  let!(:assignment) { create(:dossier_assignment, engagement: engagement, client: northwind, project: "Ticketing") }

  def texts = all("[data-testid='achievement-link']").map(&:text)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds an Achievement from its Assignment, back on the Assignment with a toast" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      click_link "Add Achievement"
      expect(page).to have_select("Assignment", selected: "NTA - Ticketing (Mar 2019 – Jun 2022)")

      fill_in "Achievement", with: "Ran daily defect triage to prioritise UAT defects."
      fill_in "Impact", with: "40% fewer production defects"
      select "5 (highest)", from: "Importance"
      fill_in "Technical Skills", with: "Jira, Excel"
      click_button "Create Achievement"

      expect(page).to have_current_path(dossier_assignment_path(assignment))
      expect(page).to have_css("[data-testid='flash-success']", text: "Ran daily defect triage to prioritise UAT defects. has been successfully created")
      within("[data-testid='assignment-achievements'] thead") do
        expect(page.all("th").map(&:text)).to eq(%w[Achievements Importance Sort])
      end
      within("[data-testid='achievement-row']") do
        expect(page).to have_link("Ran daily defect triage to prioritise UAT defects.")
        expect(page).to have_selector("[data-testid='achievement-row-importance']", exact_text: "5")
        expect(page).to have_content("Impact: 40% fewer production defects")
        expect(page).to have_selector("strong", text: "Impact:")
        # Technical Skills are on the Achievement's page, not its row.
        expect(page).to have_no_link("Jira")
      end
    end

    it "Shows, updates and deletes an Achievement" do
      achievement = create(:dossier_achievement, assignment: assignment, text: "Coordinated UAT.", skills_text: "Jira")
      sign_in_as(charlie)
      visit dossier_achievement_path(achievement)
      expect(page).to have_selector("[data-testid='achievement-text']", text: "Coordinated UAT.")
      expect(page).to have_selector("[data-testid='achievement-importance']", text: "3 (default)")
      expect(page).to have_link("Jira")

      click_link "Edit Achievement"
      fill_in "Achievement", with: "Coordinated UAT for each monthly release."
      click_button "Update Achievement"
      expect(page).to have_css("[data-testid='flash-success']", text: "Coordinated UAT for each monthly release. has been successfully updated")

      click_button "Delete Achievement"
      expect(page).to have_current_path(dossier_assignment_path(assignment))
      expect(page).to have_css("[data-testid='flash-success']", text: "Coordinated UAT for each monthly release. has been successfully deleted")
      expect(page).to have_selector("[data-testid='achievements-empty']")
      expect(achievement.reload.deleted_at).to be_present
    end

    it "Reorders Achievements with Up and Down" do
      %w[First Second Third].each { |text| create(:dossier_achievement, assignment: assignment, text: text) }
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      all("[data-testid='achievement-move-up']").last.click
      expect(texts).to eq(%w[First Third Second])
      all("[data-testid='achievement-move-down']").first.click
      expect(texts).to eq(%w[Third First Second])
    end
    it "Lists every Achievement by Engagement › Assignment on My Career › Achievements" do
      older = create(:dossier_engagement, user: charlie, employer: northwind, position_title: "Test Lead",
                                          start_month: "2015-01", end_month: "2018-12")
      older_assignment = create(:dossier_assignment, engagement: older, client: northwind, project: "Rail")
      create(:dossier_assignment, engagement: older, client: northwind, project: "Nothing To Say")
      create(:dossier_achievement, assignment: older_assignment, text: "Automated the rail regression suite.")
      create(:dossier_achievement, assignment: assignment, text: "Ran daily defect triage.")
      create(:dossier_achievement, assignment: assignment, text: "Coordinated UAT.")
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Achievements" }

      expect(all("[data-testid='achievements-engagement-title']").map(&:text))
        .to eq([ "Test Manager at Northwind Transport Authority", "Test Lead at Northwind Transport Authority" ])
      expect(all("[data-testid='achievements-assignment-title']").map(&:text)).to eq([ "NTA - Ticketing", "NTA - Rail" ])
      expect(texts).to eq([ "Ran daily defect triage.", "Coordinated UAT.", "Automated the rail regression suite." ])
      expect(page).not_to have_selector("[data-testid='achievement-move-up']")
    end

    it "Restores a deleted Achievement to its old place" do
      first = create(:dossier_achievement, assignment: assignment, text: "First")
      create(:dossier_achievement, assignment: assignment, text: "Second")
      first.soft_delete!
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Deleted Achievements" }

      within("[data-testid='deleted-achievement-row']") do
        expect(page).to have_selector("[data-testid='deleted-achievement-text']", text: "First")
        expect(page).to have_selector("[data-testid='deleted-achievement-days-remaining']", text: "30")
      end
      find("[data-testid='restore-achievement-#{first.id}']").click

      expect(page).to have_css("[data-testid='flash-success']", text: "First has been successfully restored")
      expect(page).to have_selector("[data-testid='empty-state']", text: "No deleted Achievements.")
      visit dossier_assignment_path(assignment)
      expect(texts).to eq(%w[First Second])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows errors and saves nothing without an Assignment or text" do
      sign_in_as(charlie)
      visit new_dossier_achievement_path
      click_button "Create Achievement"

      expect(page).to have_content("Assignment must exist")
      expect(page).to have_content("Text can't be blank")
      expect(Dossier::Achievement.count).to eq(0)
    end

    it "Sends 'Uno User' back to the Dossier landing page" do
      sign_in_as(uno)
      visit new_dossier_achievement_path
      expect(page).to have_current_path(dossier_path)
    end

    it "Lists and restores only your own deleted Achievements" do
      achievement = create(:dossier_achievement, assignment: assignment, text: "Charlie's bullet")
      achievement.soft_delete!
      sign_in_as(chris)
      visit deleted_dossier_achievements_path
      expect(page).to have_selector("[data-testid='empty-state']")

      page.driver.submit :post, restore_dossier_achievement_path(achievement), {}
      expect(page).to have_current_path(dossier_engagements_path)
      expect(achievement.reload.deleted_at).to be_present
    end

    it "Shows an empty Achievements page with a prompt" do
      sign_in_as(charlie)
      visit dossier_achievements_path
      expect(page).to have_selector("[data-testid='empty-state']")
      expect(page).to have_link("Write An Achievement", href: new_dossier_achievement_path)
    end

    it "Hides another Content Creator's Achievement, and offers only your own Assignments" do
      achievement = create(:dossier_achievement, assignment: assignment)
      sign_in_as(chris)
      visit dossier_achievement_path(achievement)
      expect(page).to have_current_path(dossier_engagements_path)

      visit new_dossier_achievement_path(assignment_id: assignment.id)
      expect(page).not_to have_select("Assignment", with_options: [ "NTA - Ticketing (Mar 2019 – Jun 2022)" ])
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Is reachable from the left nav's Write An Achievement" do
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Write An Achievement" }
      expect(page).to have_current_path(new_dossier_achievement_path)
    end

    it "Writes an Achievement choosing the Assignment, grouped by Engagement" do
      sign_in_as(charlie)
      visit new_dossier_achievement_path
      expect(page).to have_css("optgroup[label='Test Manager at Northwind Transport Authority']")
      select "NTA - Ticketing (Mar 2019 – Jun 2022)", from: "Assignment"
      fill_in "Achievement", with: "Made the case for portfolio-level testing."
      click_button "Create Achievement"

      expect(page).to have_current_path(dossier_assignment_path(assignment))
      expect(texts).to eq([ "Made the case for portfolio-level testing." ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Hides a deleted Achievement from its owner" do
      achievement = create(:dossier_achievement, assignment: assignment)
      achievement.soft_delete!
      sign_in_as(charlie)
      visit dossier_achievement_path(achievement)
      expect(page).to have_current_path(dossier_engagements_path)
    end

    it "Disables Up on the first Achievement and Down on the last" do
      2.times { create(:dossier_achievement, assignment: assignment) }
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      expect(all("[data-testid='achievement-move-up']").first).to be_disabled
      expect(all("[data-testid='achievement-move-down']").last).to be_disabled
    end
  end
end
