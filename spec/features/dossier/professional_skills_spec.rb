# spec/features/dossier/professional_skills_spec.rb
require "rails_helper"

# Professional Skills are tagged on Achievements like any Skill, but listed
# as examples rather than years: on My Skills and on the Skill's page, each
# Achievement with its situation and impact.
RSpec.describe "Dossier Professional Skills", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:adam) { create(:user, :admin) }
  let(:soft) { create(:dossier_skill_category, name: "Professional Skills", soft: true) }
  let!(:leadership) { create(:dossier_skill, name: "Leadership", skill_category: soft) }
  let(:assignment) do
    create(:dossier_assignment, engagement: create(:dossier_engagement, user: charlie, start_month: "2020-01", end_month: "2021-12"),
                                client: create(:dossier_organisation, name: "Westpac"), start_month: "2020-01", end_month: "2021-12")
  end

  def leadership_achievement(**attributes)
    create(:dossier_achievement, assignment: assignment, text: "Ran the vendors' joint triage", impact: "Outages halved",
                                 situation: "Two vendors blamed each other for outages", skills_text: "Leadership, Jira", **attributes)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds an Achievement with its situation, tagged with a Professional Skill" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      click_link "Add Achievement"
      fill_in "Situation", with: "Two vendors blamed each other for outages"
      fill_in "Achievement", with: "Ran the vendors' joint triage"
      fill_in "Skills", with: "Leadership"
      click_button "Create Achievement"

      click_link "Ran the vendors' joint triage"
      expect(page).to have_selector("[data-testid='achievement-situation']", text: "Two vendors blamed each other for outages")
      expect(page).to have_link("Leadership", href: dossier_skill_path(leadership))
    end

    it "Lists Professional Skills on My Skills by their examples, not years" do
      leadership_achievement
      sign_in_as(charlie)
      visit dossier_my_skills_path

      panel = find("[data-testid='my-professional-skills']")
      row = panel.find("[data-testid='my-professional-skill-row']")
      expect(row).to have_link("Leadership", href: dossier_skill_path(leadership))
      expect(row.find("[data-testid='my-professional-skill-examples']")).to have_text("1")
      expect(row).to have_text("Dec 2021")
      expect(all("[data-testid='my-skill-row']").map { |r| r.first("td").text }).to eq([ "Jira" ])
    end

    it "Shows a Professional Skill's examples on its page, with situation, impact and Assignment" do
      leadership_achievement
      sign_in_as(charlie)
      visit dossier_skill_path(leadership)

      example = find("[data-testid='skill-example']")
      expect(example).to have_link("Ran the vendors' joint triage")
      expect(example.find("[data-testid='skill-example-situation']")).to have_text("Two vendors blamed each other for outages")
      expect(example.find("[data-testid='skill-example-impact']")).to have_text("Outages halved")
      expect(example).to have_link(assignment.to_toast_label, href: dossier_assignment_path(assignment))
      expect(page).not_to have_selector("[data-testid='skill-experience-duration']")
    end

    it "Lets Adam mark a Skill Category as soft" do
      category = create(:dossier_skill_category, name: "People Skills")
      sign_in_as(adam)
      visit edit_dossier_skill_category_path(category)
      check "Professional (Soft) Skills"
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

    it "Keeps the situation of Charlie's public Achievement from Chris" do
      achievement = leadership_achievement(classification: "unrestricted")
      assignment.update!(classification: "unrestricted")
      assignment.engagement.update!(classification: "unrestricted")
      sign_in_as(create(:user, :content_creator))
      visit dossier_achievement_path(achievement)

      expect(page).to have_selector("[data-testid='achievement-text']", text: "Ran the vendors' joint triage")
      expect(page).not_to have_selector("[data-testid='achievement-situation']")
    end

    it "Shows Chris none of Charlie's examples" do
      leadership_achievement
      sign_in_as(create(:user, :content_creator))
      visit dossier_skill_path(leadership)

      expect(page).not_to have_selector("[data-testid='skill-example']")
      expect(page).not_to have_text("Two vendors blamed each other")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows an example with no situation or impact as just the Achievement" do
      leadership_achievement(situation: nil, impact: nil)
      sign_in_as(charlie)
      visit dossier_skill_path(leadership)

      example = find("[data-testid='skill-example']")
      expect(example).not_to have_selector("[data-testid='skill-example-situation']")
      expect(example).not_to have_selector("[data-testid='skill-example-impact']")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves the Professional Skills panel off My Skills until one is tagged" do
      create(:dossier_achievement, assignment: assignment, skills_text: "Jira")
      sign_in_as(charlie)
      visit dossier_my_skills_path

      expect(page).not_to have_selector("[data-testid='my-professional-skills']")
      expect(page).to have_selector("[data-testid='my-skill-row']", count: 1)
    end

    it "Says Professional Skills on a soft category's page" do
      sign_in_as(charlie)
      visit dossier_skill_category_path(soft)

      expect(page).to have_selector("[data-testid='detail-soft']", text: "Yes")
    end
  end
end
