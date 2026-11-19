# spec/requests/dossier/assignment_changes_spec.rb
require "rails_helper"

# Editing, deleting and restoring an Assignment directly, for those who may
# and those who may not.
RSpec.describe "Dossier Assignment changes", type: :request do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }

  let(:engagement) { create(:dossier_engagement, user: charlie, start_month: "2019-03", end_month: "2022-06") }
  let!(:assignment) { create(:dossier_assignment, engagement: engagement, project: "Upgrade", start_month: "2019-03", end_month: "2020-01") }

  def refused
    expect(response).to redirect_to(dossier_engagements_path)
    expect(flash[:alert]).to eq("Not authorised.")
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Lets Charlie rename their Assignment" do
      sign_in_as(charlie)
      patch dossier_assignment_path(assignment), params: { dossier_assignment: { project: "Migration" } }

      expect(response).to redirect_to(dossier_assignment_path(assignment))
      expect(assignment.reload.project).to eq("Migration")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Refuses Chris editing Charlie's Assignment" do
      sign_in_as(chris)
      patch dossier_assignment_path(assignment), params: { dossier_assignment: { project: "Hijacked" } }

      refused
      expect(assignment.reload.project).to eq("Upgrade")
    end

    it "Refuses Chris deleting Charlie's Assignment" do
      sign_in_as(chris)
      delete dossier_assignment_path(assignment)

      refused
      expect(assignment.reload.deleted_at).to be_nil
    end

    it "Refuses Chris restoring Charlie's deleted Assignment" do
      assignment.soft_delete!
      sign_in_as(chris)
      post restore_dossier_assignment_path(assignment)

      refused
      expect(assignment.reload.deleted_at).to be_present
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Shows the form again when an edit leaves the Assignment outside its Engagement" do
      sign_in_as(charlie)
      patch dossier_assignment_path(assignment), params: { dossier_assignment: { start_year: "2018", start_month_number: "1" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(assignment.reload.start_on).to eq(Date.new(2019, 3, 1))
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Refuses deleting an Assignment that's already deleted" do
      assignment.soft_delete!
      sign_in_as(charlie)
      delete dossier_assignment_path(assignment)

      refused
    end
  end
end
