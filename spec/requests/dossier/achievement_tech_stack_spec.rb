# spec/requests/dossier/achievement_tech_stack_spec.rb
require "rails_helper"

# Saving an Achievement adds its Tech Skills to its Assignment's Tech Stack,
# only when the save goes through and only for someone allowed to make it;
# saving an Assignment warns about Stack Skills no Achievement names.
RSpec.describe "Dossier Achievements and the Tech Stack", type: :request do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:adam)    { create(:user, :admin) }

  let!(:methods)       { create(:dossier_skill_category, name: "Methods & Processes", position: 2) }
  let!(:test_strategy) { create(:dossier_skill, name: "Test Strategy", skill_category: methods) }

  let(:engagement) { create(:dossier_engagement, user: charlie) }
  let(:assignment) { create(:dossier_assignment, engagement: engagement) }
  let(:achievement) { create(:dossier_achievement, assignment: assignment, text: "Wrote the test strategy") }

  def update(text: "Wrote the project's test strategy")
    patch dossier_achievement_path(achievement), params: { dossier_achievement: { text: text, skills_text: "Test Strategy" } }
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Adds the Tech Skill to Charlie's Stack when Charlie updates the Achievement" do
      sign_in_as(charlie)
      update

      expect(flash[:tech_stack]).to eq("Added Test Strategy to the Tech Stack")
      expect(assignment.reload.skills_in(:methodology)).to eq([ test_strategy ])
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Changes no Stack when the Achievement doesn't save" do
      sign_in_as(charlie)
      update(text: "")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash[:tech_stack]).to be_nil
      expect(assignment.reload.skills).to be_empty
    end

    it "Leaves Charlie's Stack alone when Chris tries to update the Achievement" do
      sign_in_as(chris)
      update

      expect(response).to redirect_to(dossier_engagements_path)
      expect(assignment.reload.skills).to be_empty
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Adds the Tech Skill to Charlie's Stack when Adam Admin updates the Achievement" do
      sign_in_as(adam)
      update

      expect(assignment.reload.skills_in(:methodology)).to eq([ test_strategy ])
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Doesn't warn when creating an Assignment, which has no Achievements yet" do
      sign_in_as(charlie)
      post dossier_assignments_path, params: { dossier_assignment: {
        engagement_id: engagement.id, client_id: create(:dossier_organisation).id, start_year: "2020", start_month_number: "1",
        end_year: "2021", end_month_number: "6", systems_under_test_na: "1", category_skills_text: { methods.id.to_s => "Test Strategy" }
      } }

      expect(response).to have_http_status(:redirect)
      expect(Dossier::Assignment.last.skills_in(:methodology)).to eq([ test_strategy ])
      expect(flash[:warning]).to be_nil
    end
  end
end
