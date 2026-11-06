# spec/features/guide_pages/story_guide_images_spec.rb
require "rails_helper"

# Takes the screenshots for the User Guide's story (docs/user-guide/story/
# images), in the shared story world (spec/support/guide_story_world.rb).
# Skipped unless GUIDE_SCREENSHOTS=1 (see spec/support/guide_images.rb):
#
#   GUIDE_SCREENSHOTS=1 bundle exec rspec spec/features/guide_pages/story_guide_images_spec.rb
#
# spec/features/guide_pages/story_world_spec.rb checks, on every CI run, that
# what these screenshots show is still true.
RSpec.describe "Story Guide Images", type: :feature, js: true, guide_image: true do
  include ActiveSupport::Testing::TimeHelpers

  # Before the world is built (let! is a before hook too), so its dates are fixed.
  before { travel_to GuideStoryWorld::STORY_TIME }
  after  { travel_back }

  let!(:world) { build_story_world }

  def open_dropdown(testid)
    find("[data-testid='#{testid}'] button").click
    expect(page).to have_css("[data-testid='#{testid}-menu']", visible: :visible)
  end

  # ── Chapter 1: Gary Guest ─────────────────────────────────────────────────
  describe "Gary Guest" do
    it "Captures the home page and the top nav's menus" do
      visit root_path
      capture_guide_image("home-grid", as: "story/gary_home")

      open_dropdown("top-nav-apps")
      capture_guide_image(%w[top-nav top-nav-apps-menu], as: "story/gary_apps_menu")
      open_dropdown("top-nav-info")
      capture_guide_image(%w[top-nav top-nav-info-menu], as: "story/gary_info_menu")
    end

    it "Captures the Info pages" do
      visit about_path
      capture_guide_image("about-layout", as: "story/gary_about")
      visit contact_path
      capture_guide_image("contact-panel", as: "story/gary_contact")
    end

    it "Captures each app's landing page and left nav" do
      { "chronicle" => chronicle_path, "cookbook" => cookbook_path, "occasions" => event_tracker_path }.each do |app, path|
        visit path
        capture_guide_image("app-landing", as: "story/gary_#{app}_landing")
        page.execute_script("document.querySelector('[data-testid=\"left-nav\"]').style.height = 'auto'")
        capture_guide_image("left-nav", as: "story/gary_#{app}_left_nav")
      end
    end

    it "Captures what Gary sees of Charlie's content" do
      visit blog_posts_path(category_id: BlogCategory.find_by!(name: "Science").id)
      capture_guide_image("browse-preview", as: "story/gary_blog_posts")

      visit blog_post_path(world.posts[:newton])
      capture_guide_image(%w[likes-panel comments-panel], as: "story/gary_blog_post_comments")

      visit events_by_month_path(month: 11)
      capture_guide_image("event-list", as: "story/gary_events_by_month")

      visit browse_by_cuisine_recipes_path
      capture_guide_image("browse-tree", as: "story/gary_browse_by_cuisine")
    end
  end

  # ── Chapter 2: Gary Signs Up ──────────────────────────────────────────────
  describe "Gary Signs Up" do
    it "Captures the sign-up journey" do
      visit root_path
      capture_guide_image("home-audience-friends", as: "story/gary_sign_up_button")

      visit sign_up_path
      fill_in "First name", with: "Gary"
      fill_in "Last name", with: "Guest"
      attach_file "Profile image", Rails.root.join("docs/test-data/images/Test_User_Gary_Guest.png"), make_visible: true
      fill_in "Email address", with: "gary@example.com"
      fill_in "Password", with: "password123"
      fill_in "Password confirmation", with: "password123"
      fill_in "Message to admin", with: "Hi! Ulrika and Charlie told me about the site."
      capture_guide_image("sign-up-info", as: "story/gary_sign_up_info")
      capture_guide_image("sign-up-panel", as: "story/gary_sign_up_form")

      click_button "Sign Up"
      expect(page).to have_css("[data-testid='flash-notice']")
      capture_guide_image("flash-notice", as: "story/gary_sign_up_submitted")
    end
  end
end
