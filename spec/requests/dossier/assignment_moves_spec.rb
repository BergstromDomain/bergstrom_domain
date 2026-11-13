# spec/requests/dossier/assignment_moves_spec.rb
require "rails_helper"

# Up/Down on the Engagement page re-sorts its Assignments, for those who may
# update them; the page comes back at the same URL so Turbo keeps the scroll.
RSpec.describe "Dossier Assignment moves", type: :request do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:adam)    { create(:user, :admin) }

  let(:engagement) { create(:dossier_engagement, user: charlie, start_month: "2019-03", end_month: "2022-06") }
  let!(:older) { create(:dossier_assignment, engagement: engagement, start_month: "2019-03", end_month: "2020-01") }
  let!(:newer) { create(:dossier_assignment, engagement: engagement, start_month: "2020-02", end_month: "2022-06") }

  def order = engagement.reload.assignments.to_a
  def move(assignment, direction) = patch(move_dossier_assignment_path(assignment, direction: direction))

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Moves Charlie's Assignment up and returns to the Engagement page" do
      sign_in_as(charlie)
      move(older, "up")

      expect(response).to redirect_to(dossier_engagement_path(engagement))
      expect(order).to eq([ older, newer ])
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Refuses Chris, leaving Charlie's order" do
      sign_in_as(chris)
      move(older, "up")

      expect(response).to redirect_to(dossier_engagements_path)
      expect(flash[:alert]).to eq("Not authorised.")
      expect(order).to eq([ newer, older ])
    end

    it "Sends Gary to sign in" do
      move(older, "up")

      expect(response).to redirect_to(new_session_path)
      expect(order).to eq([ newer, older ])
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Lets Adam re-sort Charlie's Assignments" do
      sign_in_as(adam)
      move(newer, "down")

      expect(order).to eq([ older, newer ])
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Treats an unknown direction as down, and moving the bottom one down as no change" do
      sign_in_as(charlie)
      move(older, "sideways")

      expect(response).to redirect_to(dossier_engagement_path(engagement))
      expect(order).to eq([ newer, older ])
    end
  end
end
