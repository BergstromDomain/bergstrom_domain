# spec/features/layouts/left_nav_visibility_spec.rb
require "rails_helper"

RSpec.describe "Left Nav Visibility Toggle", type: :feature do
  let(:user) { create(:user, :content_creator) }

  # See spec/features/shared/confirm_dialog_spec.rb for provenance — sign-in
  # under the JS driver is occasionally flaky (a real click not dispatching),
  # so retry and wait for a definite signed-in marker rather than trusting
  # sign_in_as's redirect landed.
  def sign_in_and_settle(user, attempts: 3)
    attempts.times do
      sign_in_as(user)
      return if page.has_css?("[data-testid='user-thumbnail-dropdown']", wait: 8)
    end
    raise "sign_in_and_settle: could not sign in as #{user.email_address} after #{attempts} attempts"
  end

  # Waits for left_nav_controller.js's background persist to finish before
  # doing anything that depends on it (e.g. reloading the page) — see
  # left_nav_controller.js's own comment on data-left-nav-syncing.
  def wait_for_left_nav_sync
    expect(page).to have_css("[data-controller='left-nav'][data-left-nav-syncing='false']", wait: 5)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Collapses the nav to a thin strip and back again", js: true do
      sign_in_and_settle(user)
      visit event_types_path

      expect(page).to have_css("[data-testid='left-nav-collapse']")
      js_click("left-nav-collapse")

      expect(page).to have_no_css("[data-testid='left-nav-collapse']")
      expect(page).to have_css("[data-testid='left-nav-restore']")
      wait_for_left_nav_sync

      js_click("left-nav-restore")

      expect(page).to have_css("[data-testid='left-nav-collapse']")
      expect(page).to have_no_css("[data-testid='left-nav-restore']")
      wait_for_left_nav_sync
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Renders no toggle controls at all for a guest (no session to persist to)", js: true do
      visit event_types_path

      expect(page).to have_no_css("[data-testid='left-nav-collapse']")
      expect(page).to have_no_css("[data-testid='left-nav-restore']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Stays collapsed across a second page load within the same app/section", js: true do
      sign_in_and_settle(user)
      visit event_types_path
      js_click("left-nav-collapse")
      wait_for_left_nav_sync

      visit people_path # also :event_tracker — same section

      expect(page).to have_no_css("[data-testid='left-nav-collapse']")
      expect(page).to have_css("[data-testid='left-nav-restore']")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Restores automatically when navigating to a different app/section", js: true do
      sign_in_and_settle(user)
      visit event_types_path
      js_click("left-nav-collapse")
      wait_for_left_nav_sync

      visit blog_categories_path # :blog_posts — a different section

      expect(page).to have_css("[data-testid='left-nav-collapse']")
      expect(page).to have_no_css("[data-testid='left-nav-restore']")
    end
  end
end
