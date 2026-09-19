# spec/requests/left_navs_spec.rb
require "rails_helper"

RSpec.describe "LeftNavs", type: :request do
  let(:user) { create(:user, :content_creator) }

  def current_session
    Session.find_by(user: user)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "toggles the whole nav's visibility" do
      sign_in_as(user)
      expect { patch toggle_visibility_left_nav_path }
        .to change { current_session.reload.left_nav_visible }.from(true).to(false)
      expect(response).to have_http_status(:no_content)
    end

    it "toggles a section's collapsed state by key" do
      sign_in_as(user)
      expect { patch toggle_section_left_nav_path, params: { key: "blog_posts:views" } }
        .to change { current_session.reload.left_nav_section_collapsed?("blog_posts:views") }
        .from(false).to(true)
      expect(response).to have_http_status(:no_content)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "redirects a guest to sign in when toggling visibility" do
      patch toggle_visibility_left_nav_path
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects a guest to sign in when toggling a section" do
      patch toggle_section_left_nav_path, params: { key: "blog_posts:views" }
      expect(response).to redirect_to(new_session_path)
    end

    it "responds with a bad request when no key is given for toggle_section" do
      sign_in_as(user)
      patch toggle_section_left_nav_path
      expect(response).to have_http_status(:bad_request)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "toggling twice restores the original visibility" do
      sign_in_as(user)
      patch toggle_visibility_left_nav_path
      patch toggle_visibility_left_nav_path
      expect(current_session.reload.left_nav_visible).to be true
    end

    it "toggling a section twice expands it again" do
      sign_in_as(user)
      patch toggle_section_left_nav_path, params: { key: "blog_posts:views" }
      patch toggle_section_left_nav_path, params: { key: "blog_posts:views" }
      expect(current_session.reload.left_nav_section_collapsed?("blog_posts:views")).to be false
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "toggling one section key never affects a different key" do
      sign_in_as(user)
      patch toggle_section_left_nav_path, params: { key: "blog_posts:views" }
      patch toggle_section_left_nav_path, params: { key: "event_tracker:views" }

      session = current_session.reload
      expect(session.left_nav_section_collapsed?("blog_posts:views")).to be true
      expect(session.left_nav_section_collapsed?("event_tracker:views")).to be true
      expect(session.left_nav_section_collapsed?("blog_posts:actions")).to be false
    end
  end
end
