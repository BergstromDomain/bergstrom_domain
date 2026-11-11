# spec/features/dossier/soft_skills_spec.rb
require "rails_helper"

# Soft Skills are ticked on Achievements and Contributions (technical ones are
# typed), shown on an Achievement's row with its Situation and Impact, and
# collected on My Career › Soft Skills as examples, rather than years.
RSpec.describe "Dossier Soft Skills", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris) { create(:user, :content_creator) }
  let(:adam) { create(:user, :admin) }
  let(:soft) { create(:dossier_skill_category, name: "Soft Skills", soft: true) }
  let!(:leadership) { create(:dossier_skill, name: "Leadership", skill_category: soft, description: "Leading people and teams.") }
  let!(:knowledge) { create(:dossier_skill, name: "Knowledge Sharing", skill_category: soft) }
  let!(:jira) { create(:dossier_skill, name: "Jira", skill_category: create(:dossier_skill_category, name: "Test Tools")) }
  let(:assignment) do
    create(:dossier_assignment, engagement: create(:dossier_engagement, user: charlie, start_month: "2020-01", end_month: "2021-12"),
                                client: create(:dossier_organisation, name: "Westpac"), start_month: "2020-01", end_month: "2021-12")
  end

  def leadership_achievement(**attributes)
    create(:dossier_achievement, assignment: assignment, text: "Ran the vendors' joint triage", impact: "Outages halved",
                                 situation: "Two vendors blamed each other for outages", skills_text: "Jira",
                                 soft_skill_ids: [ leadership.id ], **attributes)
  end

  def make_public(achievement)
    [ achievement, assignment, assignment.engagement ].each { |record| record.update!(classification: "unrestricted") }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds an Achievement with its situation, a ticked Soft Skill and a typed Technical Skill" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      click_link "Add Achievement"
      fill_in "Situation", with: "Two vendors blamed each other for outages"
      fill_in "Achievement", with: "Ran the vendors' joint triage"
      check "Leadership"
      fill_in "Technical Skills", with: "Jira"
      click_button "Create Achievement"

      click_link "Ran the vendors' joint triage"
      expect(page).to have_selector("[data-testid='achievement-situation']", text: "Two vendors blamed each other for outages")
      expect(find("[data-testid='achievement-soft-skills']")).to have_link("Leadership", href: dossier_skill_path(leadership))
      expect(find("[data-testid='achievement-skills']")).to have_link("Jira").and have_no_text("Leadership")
    end

    it "Shows an Achievement's Situation, Impact and Soft Skills on its row, in STAR order, without its Technical Skills" do
      leadership_achievement
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      row = find("[data-testid='achievement-row']")
      expect(row.find("[data-testid='achievement-row-situation']")).to have_text("Situation: Two vendors blamed each other for outages")
      expect(row.find("[data-testid='achievement-row-impact']")).to have_text("Impact: Outages halved")
      expect(row.find("[data-testid='achievement-row-skills']")).to have_text("Soft Skills: Leadership")
      expect(row).to have_no_link("Jira")
      expect(row.text).to match(/Situation:.*Impact:.*Soft Skills:/m)
    end

    it "Collects each Soft Skill's examples on My Career › Soft Skills, Achievements and Contributions" do
      leadership_achievement
      create(:dossier_contribution, user: charlie, title: "Statistical Methods", soft_skill_ids: [ knowledge.id ],
                                    event: create(:dossier_organisation, name: "All Things Testing"))
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Soft Skills" }

      expect(page).to have_current_path(dossier_soft_skills_path)
      expect(all("[data-testid='soft-skill-heading']").map(&:text)).to eq([ "Knowledge Sharing", "Leadership" ])
      leading = find("[data-testid='soft-skill-#{leadership.id}']")
      expect(leading).to have_text("Leading people and teams.")
      example = leading.find("[data-testid='skill-example']")
      expect(example).to have_link("Ran the vendors' joint triage")
      expect(example.find("[data-testid='skill-example-situation']")).to have_text("Two vendors blamed each other for outages")
      expect(example.find("[data-testid='skill-example-impact']")).to have_text("Outages halved")
      expect(example).to have_link(assignment.to_toast_label, href: dossier_assignment_path(assignment))
      sharing = find("[data-testid='soft-skill-#{knowledge.id}']")
      expect(sharing.find("[data-testid='skill-example-contribution']")).to have_link("Statistical Methods").and have_text("Talk").and have_text("All Things Testing")
    end

    it "Shows a Soft Skill's examples on its page, with situation, impact and Assignment" do
      leadership_achievement
      sign_in_as(charlie)
      visit dossier_skill_path(leadership)

      example = find("[data-testid='skill-example']")
      expect(example).to have_link("Ran the vendors' joint triage")
      expect(example.find("[data-testid='skill-example-situation']")).to have_text("Two vendors blamed each other for outages")
      expect(page).not_to have_selector("[data-testid='skill-experience-duration']")
    end

    it "Lets Adam mark a Skill Category as soft" do
      category = create(:dossier_skill_category, name: "People Skills")
      sign_in_as(adam)
      visit edit_dossier_skill_category_path(category)
      check "Soft Skills"
      click_button "Update Skill Category"

      expect(page).to have_selector("[data-testid='detail-soft']", text: "Yes")
      expect(category.reload).to be_soft
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Doesn't let Charlie change a Skill Category" do
      sign_in_as(charlie)
      visit edit_dossier_skill_category_path(soft)

      expect(page).to have_text("Not authorised.")
    end

    it "Keeps the situation of Charlie's public Achievement from Chris, on its page and its row" do
      achievement = leadership_achievement
      make_public(achievement)
      sign_in_as(chris)
      visit dossier_achievement_path(achievement)

      expect(page).to have_selector("[data-testid='achievement-text']", text: "Ran the vendors' joint triage")
      expect(page).not_to have_selector("[data-testid='achievement-situation']")

      visit dossier_assignment_path(assignment)
      expect(find("[data-testid='achievement-row']")).to have_text("Soft Skills: Leadership")
      expect(page).not_to have_selector("[data-testid='achievement-row-situation']")
    end

    it "Shows Chris none of Charlie's examples, on the Skill page or his own Soft Skills page" do
      leadership_achievement
      create(:dossier_contribution, user: charlie, title: "Charlie's Talk", soft_skill_ids: [ leadership.id ])
      sign_in_as(chris)
      visit dossier_skill_path(leadership)
      expect(page).not_to have_selector("[data-testid='skill-example']")

      visit dossier_soft_skills_path
      expect(page).not_to have_text("Two vendors blamed each other")
      expect(page).not_to have_text("Charlie's Talk")
    end

    it "Keeps an App User off My Career › Soft Skills" do
      sign_in_as(create(:user))
      visit dossier_soft_skills_path

      expect(page).to have_text("Not authorised.")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Unticks a Soft Skill on Edit, keeping the Technical Skills" do
      achievement = leadership_achievement
      sign_in_as(charlie)
      visit edit_dossier_achievement_path(achievement)

      expect(page).to have_checked_field("Leadership")
      expect(page).to have_field("Technical Skills", with: "Jira")
      uncheck "Leadership"
      click_button "Update Achievement"

      expect(achievement.reload.skills).to eq([ jira ])
    end

    it "Ticks a Soft Skill on a Contribution, shown apart from its Technical Skills" do
      sign_in_as(charlie)
      visit new_dossier_contribution_path
      fill_in "Title", with: "Getting Started with Robot Framework"
      fill_in "Date Year", with: "2024"
      select "November", from: "Date Month"
      check "Knowledge Sharing"
      fill_in "Technical Skills", with: "Jira"
      click_button "Add Contribution"

      expect(find("[data-testid='contribution-soft-skills']")).to have_link("Knowledge Sharing")
      expect(find("[data-testid='contribution-skills']")).to have_link("Jira").and have_no_text("Knowledge Sharing")
    end

    it "Shows an example with no situation or impact as just the Achievement" do
      leadership_achievement(situation: nil, impact: nil)
      sign_in_as(charlie)
      visit dossier_soft_skills_path

      example = find("[data-testid='skill-example']")
      expect(example).not_to have_selector("[data-testid='skill-example-situation']")
      expect(example).not_to have_selector("[data-testid='skill-example-impact']")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Says No examples yet for a Soft Skill nothing shows" do
      leadership_achievement
      sign_in_as(charlie)
      visit dossier_soft_skills_path

      expect(find("[data-testid='soft-skill-#{knowledge.id}']")).to have_selector("[data-testid='soft-skill-empty']", text: "No examples yet.")
      expect(find("[data-testid='soft-skill-#{leadership.id}']")).to have_text("1 example")
    end

    it "Says so when there are no Soft Skills at all" do
      Dossier::Skill.where(skill_category: soft).delete_all
      sign_in_as(charlie)
      visit dossier_soft_skills_path

      expect(page).to have_selector("[data-testid='empty-state']", text: "No Soft Skills yet.")
    end

    it "Leaves the Soft Skills label off a row with only Technical Skills, and the Soft Skills off Technical Skills" do
      create(:dossier_achievement, assignment: assignment, skills_text: "Jira", soft_skill_ids: [ "" ])
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      expect(find("[data-testid='achievement-row']")).not_to have_selector("[data-testid='achievement-row-skills']")

      leadership_achievement
      visit dossier_my_skills_path
      expect(page).to have_selector("h1.page-title", text: "Technical Skills")
      expect(all("[data-testid='my-skill-row']").map { |r| r.first("td").text }).to eq([ "Jira" ])
      expect(page).not_to have_link("Leadership")
    end

    it "Says Soft Skills on a soft category's page" do
      sign_in_as(charlie)
      visit dossier_skill_category_path(soft)

      expect(page).to have_selector("[data-testid='detail-soft']", text: "Yes")
    end
  end
end
