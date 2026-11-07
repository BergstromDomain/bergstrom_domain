# spec/features/dossier/guide_claims_spec.rb
require "rails_helper"

# Checks the claims the Dossier User Guide pages (docs/user-guide/dossier)
# make that a reader could lose data over, or that decide what's on their
# CV. If one fails, the app has changed under the guide: update the page.
RSpec.describe "Dossier User Guide claims", type: :feature do
  include ActiveSupport::Testing::TimeHelpers

  let(:charlie)    { create(:user, :content_creator) }
  let(:engagement) { create(:dossier_engagement, user: charlie, end_on: nil) }
  let(:assignment) { create(:dossier_assignment, engagement: engagement) }
  let!(:achievement) { create(:dossier_achievement, assignment: assignment, text: "Raised the pass rate") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Keeps a deleted Engagement, with its Assignment and Achievement, for restoring" do
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)
      click_button "Delete Engagement"

      visit deleted_dossier_engagements_path
      find("[data-testid='restore-engagement-#{engagement.id}']").click
      expect(assignment.reload.achievements).to contain_exactly(achievement)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Hides a deleted Assignment's Achievements, and only purges them after 30 days" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      click_button "Delete Assignment"
      expect(achievement.reload).to be_hidden

      travel_to(31.days.from_now) { PurgeDeletedDossierAssignmentsJob.perform_now }
      expect(Dossier::Achievement.exists?(achievement.id)).to be(false)
    end

    it "Doesn't let an Achievement move to another Assignment" do
      other = create(:dossier_assignment, engagement: engagement)
      sign_in_as(charlie)
      visit edit_dossier_achievement_path(achievement)

      expect(page).not_to have_select("dossier_achievement[assignment_id]")
      page.driver.submit :patch, dossier_achievement_path(achievement),
        { dossier_achievement: { text: "Raised the pass rate", assignment_id: other.id } }
      expect(achievement.reload.assignment).to eq(assignment)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Restores a deleted Assignment with its Achievements and Training" do
      course = create(:dossier_credential, user: charlie, engagement: engagement, assignment: assignment)
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      click_button "Delete Assignment"
      expect(course.reload).to be_hidden

      visit deleted_dossier_assignments_path
      find("[data-testid='restore-assignment-#{assignment.id}']").click
      expect(assignment.reload.achievements).to contain_exactly(achievement)
      expect(course.reload).to have_attributes(hidden?: false, assignment_id: assignment.id)
    end

    it "Moves a purged Assignment's Training up to its Engagement" do
      course = create(:dossier_credential, user: charlie, engagement: engagement, assignment: assignment)
      assignment.soft_delete!

      travel_to(31.days.from_now) { PurgeDeletedDossierAssignmentsJob.perform_now }
      expect(course.reload).to have_attributes(assignment_id: nil, engagement_id: engagement.id)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Starts a CV Variant without Uncategorised Skills, Training or low-importance Achievements" do
      uncategorised = create(:dossier_skill, skill_category: create(:dossier_skill_category, name: "Uncategorised"))
      filed         = create(:dossier_skill, skill_category: create(:dossier_skill_category, name: "Software"))
      assignment.update!(other_tools_na: false, other_tools_text: "#{uncategorised.name}, #{filed.name}")
      minor  = create(:dossier_achievement, assignment: assignment, importance: 2)
      course = create(:dossier_credential, user: charlie)
      selection = Dossier::CvSelection.new(create(:dossier_cv_variant, user: charlie))

      expect(selection.included?(filed)).to be(true)
      expect([ selection.included?(uncategorised), selection.included?(course), selection.included?(minor) ])
        .to eq([ false, false, false ])
      expect(selection.included?(achievement)).to be(true)
    end
  end
end
