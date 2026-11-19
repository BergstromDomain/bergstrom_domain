# spec/requests/dossier/career_breaks_spec.rb
require "rails_helper"

# Only Admins set an Employment Type's Career Break flag, and a career break
# Engagement takes no Assignments, however they're posted.
RSpec.describe "Dossier career breaks", type: :request do
  let(:charlie) { create(:user, :content_creator) }
  let(:type)    { create(:dossier_employment_type, name: "Time Off") }
  let(:time_off) { create(:dossier_engagement, :career_break, user: charlie, start_month: "2012-10", end_month: "2013-04") }

  def flag(type) = patch(dossier_employment_type_path(type), params: { dossier_employment_type: { career_break: "1" } })

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Lets Adam set the Career Break flag" do
      sign_in_as(create(:user, :admin))
      flag(type)
      expect(type.reload.career_break).to be(true)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Refuses Charlie setting the Career Break flag" do
      sign_in_as(charlie)
      flag(type)

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to eq("Not authorised.")
      expect(type.reload.career_break).to be(false)
    end

    it "Sends Gary to sign in" do
      flag(type)
      expect(response).to redirect_to(new_session_path)
    end

    it "Refuses an Assignment posted directly under a career break" do
      sign_in_as(charlie)
      expect do
        post dossier_assignments_path, params: { dossier_assignment: { engagement_id: time_off.id, start_year: "2012", start_month_number: "11" } }
      end.not_to change(Dossier::Assignment, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Lets Charlie create a career break with no Employer" do
      sign_in_as(charlie)
      expect do
        post dossier_engagements_path, params: { dossier_engagement: {
          employment_type_id: create(:dossier_employment_type, :career_break).id, position_title: "Unemployed",
          start_year: "2024", start_month_number: "8", end_year: "2024", end_month_number: "9"
        } }
      end.to change(Dossier::Engagement, :count).by(1)
      expect(Dossier::Engagement.last.employer).to be_nil
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Won't let a career break type become permanent too" do
      sign_in_as(create(:user, :admin))
      type.update!(career_break: true)
      patch dossier_employment_type_path(type), params: { dossier_employment_type: { permanent: "1" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(type.reload.permanent).to be(false)
    end
  end
end
