# spec/features/dossier/skill_contributions_spec.rb
require "rails_helper"

# A Skill's page lists the signed-in user's own Contributions tagged with it:
# a technical Skill in a "Your Contributions" panel after Your Experience, a
# soft Skill under its example Achievements.
RSpec.describe "Dossier Skill page Contributions", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let!(:robot)  { create(:dossier_skill, name: "Robot Framework", skill_category: create(:dossier_skill_category, name: "Test Tools")) }
  let(:soft)    { create(:dossier_skill_category, name: "Soft Skills", soft: true) }
  let(:sharing) { create(:dossier_skill, name: "Knowledge Sharing", skill_category: soft) }
  let(:event)   { create(:dossier_organisation, name: "All Things Testing") }

  def talk(user: charlie, **attributes)
    create(:dossier_contribution, user: user, title: "Getting Started with Robot Framework", event: event,
                                  start_precision: "month", **attributes)
  end

  def assignment_using(skill_text)
    engagement = create(:dossier_engagement, user: charlie, start_month: "2020-01", end_month: "2021-12")
    create(:dossier_assignment, engagement: engagement, start_month: "2020-01", end_month: "2021-12",
                                test_tools_na: false, test_tools_text: skill_text)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Lists Charlie's Contribution on a technical Skill's page, after Your Experience" do
      assignment_using("Robot Framework")
      talk(skills_text: "Robot Framework")
      sign_in_as(charlie)
      visit dossier_skill_path(robot)

      panel = find("[data-testid='skill-contributions']")
      expect(panel).to have_selector("h2", text: "Your Contributions")
      example = panel.find("[data-testid='skill-example-contribution']")
      expect(example).to have_link("Getting Started with Robot Framework")
      expect(example).to have_text("Talk").and have_link("All Things Testing").and have_text("Nov 2024")
      expect(page.text.index("Your Experience")).to be < page.text.index("Your Contributions")
    end

    it "Lists Charlie's Contribution on a soft Skill's page, after the Achievements" do
      achievement = create(:dossier_achievement, assignment: assignment_using("Jira"), text: "Ran the guild",
                                                 soft_skill_ids: [ sharing.id ])
      talk(soft_skill_ids: [ sharing.id ])
      sign_in_as(charlie)
      visit dossier_skill_path(sharing)

      examples = find("[data-testid='skill-examples']")
      expect(examples).to have_link(achievement.text)
      expect(examples).to have_selector("[data-testid='skill-example-contribution']", text: "Getting Started with Robot Framework")
      expect(examples.text.index("Ran the guild")).to be < examples.text.index("Getting Started with Robot Framework")
      expect(page).not_to have_selector("[data-testid='skill-contributions']")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows Chris none of Charlie's Contributions, even an Unrestricted one" do
      talk(skills_text: "Robot Framework", classification: "unrestricted")
      talk(soft_skill_ids: [ sharing.id ], classification: "unrestricted")
      sign_in_as(chris)

      visit dossier_skill_path(robot)
      expect(page).not_to have_selector("[data-testid='skill-contributions']")
      visit dossier_skill_path(sharing)
      expect(page).not_to have_selector("[data-testid='skill-example-contribution']")
    end

    it "Leaves out Charlie's deleted Contribution" do
      talk(skills_text: "Robot Framework").soft_delete!
      sign_in_as(charlie)
      visit dossier_skill_path(robot)

      expect(page).not_to have_selector("[data-testid='skill-contributions']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows a Contribution on a technical Skill Charlie has never used on an Assignment" do
      talk(skills_text: "Robot Framework")
      sign_in_as(charlie)
      visit dossier_skill_path(robot)

      expect(page).not_to have_selector("[data-testid='skill-experience']")
      expect(find("[data-testid='skill-contributions']")).to have_link("Getting Started with Robot Framework")
    end

    it "Shows a soft Skill's examples when its only example is a Contribution" do
      talk(soft_skill_ids: [ sharing.id ])
      sign_in_as(charlie)
      visit dossier_skill_path(sharing)

      expect(find("[data-testid='skill-examples']")).to have_selector("[data-testid='skill-example-contribution']")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Lists Contributions newest first, without an event when there's none" do
      talk(skills_text: "Robot Framework", title: "Older Talk", start_on: Date.new(2023, 5, 1))
      talk(skills_text: "Robot Framework", title: "Newer Article", kind: "article", event: nil, start_on: Date.new(2025, 2, 1))
      sign_in_as(charlie)
      visit dossier_skill_path(robot)

      rows = all("[data-testid='skill-example-contribution']")
      expect(rows.map { |row| row.first("a").text }).to eq([ "Newer Article", "Older Talk" ])
      expect(rows.first).to have_text("Article, Feb 2025")
    end

    it "Shows a guest no Contributions" do
      talk(skills_text: "Robot Framework", classification: "unrestricted")
      visit dossier_skill_path(robot)

      expect(page).not_to have_selector("[data-testid='skill-contributions']")
    end
  end
end
