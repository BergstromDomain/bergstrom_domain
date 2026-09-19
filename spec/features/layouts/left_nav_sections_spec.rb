# spec/features/layouts/left_nav_sections_spec.rb
require "rails_helper"

RSpec.describe "Left Nav Section Collapse", type: :feature do
  let(:user) { create(:user, :content_creator) }

  # See spec/features/shared/confirm_dialog_spec.rb for provenance — sign-in
  # under the JS driver is occasionally flaky, so retry and wait for a
  # definite signed-in marker rather than trusting sign_in_as's redirect.
  def sign_in_and_settle(user, attempts: 3)
    attempts.times do
      sign_in_as(user)
      return if page.has_css?("[data-testid='user-thumbnail-dropdown']", wait: 8)
    end
    raise "sign_in_and_settle: could not sign in as #{user.email_address} after #{attempts} attempts"
  end

  # See left_nav_controller.js's data-left-nav-syncing comment.
  def wait_for_left_nav_sync
    expect(page).to have_css("[data-controller='left-nav'][data-left-nav-syncing='false']", wait: 5)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Collapses and expands a section's links independently", js: true do
      sign_in_and_settle(user)
      visit event_types_path

      expect(page).to have_css("[data-testid='left-nav-event-tracker-h3']")
      js_click("left-nav-views-h2-toggle")

      expect(page).to have_no_css("[data-testid='left-nav-event-tracker-h3']")
      wait_for_left_nav_sync

      js_click("left-nav-views-h2-toggle")

      expect(page).to have_css("[data-testid='left-nav-event-tracker-h3']")
      wait_for_left_nav_sync
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Renders no section toggle for a guest (no session to persist to)", js: true do
      visit event_types_path

      expect(page).to have_no_css("[data-testid='left-nav-views-h2-toggle']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Collapsing one H2 never affects a sibling H2 in the same app", js: true do
      sign_in_and_settle(user)
      visit event_types_path
      js_click("left-nav-views-h2-toggle")
      wait_for_left_nav_sync

      expect(page).to have_no_css("[data-testid='left-nav-event-tracker-h3']")
      expect(page).to have_css("[data-testid='left-nav-how-to-h3']")
    end

    it "Stays collapsed across a second page load within the same app/section", js: true do
      sign_in_and_settle(user)
      visit event_types_path
      js_click("left-nav-views-h2-toggle")
      wait_for_left_nav_sync

      visit people_path # also :event_tracker — same section

      expect(page).to have_no_css("[data-testid='left-nav-event-tracker-h3']")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Collapsing 'Chronicle >> Views' never affects 'Occasions >> Views', despite sharing a subkey", js: true do
      sign_in_and_settle(user)
      visit blog_categories_path
      js_click("left-nav-views-h2-toggle")
      wait_for_left_nav_sync

      visit event_types_path

      expect(page).to have_css("[data-testid='left-nav-event-tracker-h3']")
    end

    it "Resets to all-expanded on the next login (model-level — see Session spec for the unit test)" do
      session = create(:session, collapsed_nav_sections: [ "event_tracker:views" ])
      expect(session.left_nav_section_collapsed?("event_tracker:views")).to be true

      fresh_session = create(:session, user: session.user)
      expect(fresh_session.left_nav_section_collapsed?("event_tracker:views")).to be false
    end
  end
end
