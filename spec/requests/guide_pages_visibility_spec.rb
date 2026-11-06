# spec/requests/guide_pages_visibility_spec.rb
require "rails_helper"

# Admin-section guide pages (Sam's chapter of the story: User Management,
# restoring data) are for system admins only — hidden from the guide index,
# search, the left-nav contents, the page itself and its screenshots.
RSpec.describe "Guide Page visibility", type: :request do
  let(:sam)     { create(:user, :system_admin) }
  let(:adam)    { create(:user, :admin) }
  let(:charlie) { create(:user, :content_creator) }

  let!(:admin_page) { create(:guide_page, title: "Sams Chapter", app_section: "admin", body: "Approving sign-ups.") }
  let!(:story_page) { create(:guide_page, title: "Garys Chapter", app_section: "story", body: "Discovering the site.") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Shows a system admin the Admin page in the index, the left nav and on its own" do
      sign_in_as(sam)

      get guide_pages_path
      expect(response.body).to include("Sams Chapter")
      expect(response.body).to include("data-testid=\"left-nav-guide-section-admin-h3\"")

      get guide_page_path(admin_page)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Approving sign-ups.")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Hides the Admin page from a guest, a content creator and an admin" do
      [ nil, charlie, adam ].each do |user|
        sign_in_as(user) if user

        get guide_pages_path
        expect(response.body).to include("Garys Chapter")
        expect(response.body).not_to include("Sams Chapter")
        expect(response.body).not_to include("left-nav-guide-section-admin-h3")

        get guide_page_path(admin_page)
        expect(response).to redirect_to(guide_pages_path)

        delete session_path if user
      end
    end

    it "Doesn't let an admin edit, update or delete an Admin page" do
      sign_in_as(adam)

      get edit_guide_page_path(admin_page)
      expect(response).to redirect_to(guide_pages_path)

      patch guide_page_path(admin_page), params: { guide_page: { title: "Changed" } }
      expect(admin_page.reload.title).to eq("Sams Chapter")

      expect { delete guide_page_path(admin_page) }.not_to change(GuidePage, :count)
    end

    it "Doesn't offer the Admin section when an admin writes a guide page" do
      sign_in_as(adam)

      get new_guide_page_path
      expect(response.body).not_to include("<option value=\"admin\">")
      expect(response.body).to include("<option value=\"story\">")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Doesn't find an Admin page through search unless you're a system admin" do
      get guide_pages_path(q: "sign-ups")
      expect(response.body).not_to include("Sams Chapter")

      sign_in_as(sam)
      get guide_pages_path(q: "sign-ups")
      expect(response.body).to include("Sams Chapter")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    let(:root) { Pathname.new(Dir.mktmpdir) }

    before do
      %w[admin story].each do |app|
        root.join(app, "images").mkpath
        root.join(app, "images", "screen.png").binwrite("\x89PNG\r\n\x1A\n".b)
      end
      stub_const("GuideImagesController::ROOT", root)
    end

    after { FileUtils.remove_entry(root) }

    it "Serves the Admin section's screenshots to system admins only" do
      get guide_image_path(app: "story", name: "screen")
      expect(response).to have_http_status(:ok)

      get guide_image_path(app: "admin", name: "screen")
      expect(response).to have_http_status(:not_found)

      sign_in_as(adam)
      get guide_image_path(app: "admin", name: "screen")
      expect(response).to have_http_status(:not_found)

      delete session_path
      sign_in_as(sam)
      get guide_image_path(app: "admin", name: "screen")
      expect(response).to have_http_status(:ok)
    end
  end
end
