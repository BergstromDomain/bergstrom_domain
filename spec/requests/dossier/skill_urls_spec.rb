# spec/requests/dossier/skill_urls_spec.rb
require "rails_helper"

# The signed-in user's own Skills pages: /dossier/my-technical-skills and
# /dossier/my-soft-skills. The old addresses redirect there for bookmarks.
RSpec.describe "Dossier Skill page URLs", type: :request do
  let(:charlie) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Serves Charlie's Technical and Soft Skills at their my- addresses" do
      sign_in_as(charlie)

      expect(dossier_my_skills_path).to eq("/dossier/my-technical-skills")
      expect(dossier_soft_skills_path).to eq("/dossier/my-soft-skills")
      [ dossier_my_skills_path, dossier_soft_skills_path ].each do |path|
        get path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Sends Gary to sign in from either page" do
      [ dossier_my_skills_path, dossier_soft_skills_path ].each do |path|
        get path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Redirects the old addresses permanently to the new ones" do
      get "/dossier/my-skills"
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/dossier/my-technical-skills")

      get "/dossier/soft-skills"
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/dossier/my-soft-skills")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Keeps the query string when redirecting an old address" do
      get "/dossier/my-skills?sort=years"

      expect(response).to redirect_to("/dossier/my-technical-skills?sort=years")
    end
  end
end
