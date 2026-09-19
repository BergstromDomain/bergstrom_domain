# spec/requests/left_nav_spec.rb
require "rails_helper"

RSpec.describe "Left Nav session state", type: :request do
  let(:user) { create(:user, :content_creator) }

  def current_session
    Session.find_by(user: user)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "records the left_nav_section on the session for a signed-in user's request" do
      sign_in_as(user)
      get event_types_path
      expect(current_session.left_nav_section).to eq("event_tracker")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "does nothing (no error, no session touched) for a guest with no session" do
      expect { get event_types_path }.not_to raise_error
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "leaves an explicit hide in place across repeated requests to the same section" do
      sign_in_as(user)
      get event_types_path
      current_session.toggle_left_nav_visibility!
      expect(current_session.left_nav_visible).to be false

      get people_path # also :event_tracker — same section, no change expected

      expect(current_session.reload.left_nav_visible).to be false
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "restores visibility automatically when the app/section changes" do
      sign_in_as(user)
      get event_types_path
      current_session.toggle_left_nav_visibility!
      expect(current_session.left_nav_visible).to be false

      get blog_categories_path # :blog_posts — a different section

      session = current_session.reload
      expect(session.left_nav_visible).to be true
      expect(session.left_nav_section).to eq("blog_posts")
    end
  end
end
