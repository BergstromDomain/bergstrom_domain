# spec/requests/recipes_convert_format_spec.rb
require "rails_helper"

RSpec.describe "Recipes #convert_format", type: :request do
  let(:charlie) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { sign_in_as(charlie) }

    it "Converts Markdown to HTML for the Formatted tab" do
      post convert_format_recipes_path, params: { source: "markdown", content: "# Pea Soup" }, as: :json
      expect(response.parsed_body["html"]).to include("<h1>Pea Soup</h1>")
    end

    it "Converts HTML back to Markdown for storage" do
      post convert_format_recipes_path, params: { source: "html", content: "<p><strong>Soak</strong></p>" }, as: :json
      expect(response.parsed_body["markdown"]).to include("**Soak**")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects 'Uno User' without converting" do
      sign_in_as(create(:user, :app_user))
      post convert_format_recipes_path, params: { source: "markdown", content: "# Hi" }, as: :json
      expect(response).to redirect_to(cookbook_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Works for a content creator whose Chronicle create permission is revoked" do
      create(:app_permission, user: charlie, app_name: "blog_posts", can_create: false)
      sign_in_as(charlie)
      post convert_format_recipes_path, params: { source: "markdown", content: "# Hi" }, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Rejects an unknown source" do
      sign_in_as(charlie)
      post convert_format_recipes_path, params: { source: "pdf", content: "x" }, as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end
end
