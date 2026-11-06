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

  # ── Chapter 3: Ulrika User ────────────────────────────────────────────────
  describe "Ulrika User" do
    def sign_in_and_wait(user)
      sign_in_as(user)
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 8)
    end

    it "Captures the user menu, comments and reactions" do
      sign_in_and_wait(world.ulrika)
      open_dropdown("user-thumbnail-dropdown")
      capture_guide_image(%w[top-nav user-thumbnail-dropdown-menu], as: "story/ulrika_user_menu")

      visit blog_post_path(world.posts[:newton])
      expect(page).to have_css("[data-testid='comment-body-field']")
      capture_guide_image(%w[likes-panel comments-panel], as: "story/ulrika_blog_post_comments")
    end

    it "Captures connecting with Charlie, and what that unlocks" do
      sign_in_and_wait(world.ulrika)
      visit contacts_path
      page.execute_script("document.querySelector('[data-testid=\"left-nav\"]').style.height = 'auto'")
      capture_guide_image("left-nav", as: "story/ulrika_settings_left_nav")

      find("[data-testid='contact-search-input']").fill_in(with: "Charlie")
      expect(page).to have_css("[data-testid='contact-search-result-row']", text: "Charlie Content Creator", wait: 8)
      capture_guide_image("new-contacts-panel", as: "story/ulrika_contact_search")

      js_click("connect-contact-#{world.charlie.id}")
      expect(page).to have_css("[data-testid='outgoing-pending-contact-row']", text: "Charlie Content Creator", wait: 8)
      capture_guide_image("outgoing-pending-contacts", as: "story/ulrika_contact_request_sent")

      # Charlie in a browser of their own, rather than signing Ulrika out.
      using_session(:charlie) do
        sign_in_and_wait(world.charlie)
        visit contacts_path
        capture_guide_image("incoming-pending-contacts", as: "story/charlie_contact_request_incoming")
        js_click("accept-contact-#{Contact.find_by!(user: world.ulrika).id}")
        expect(page).to have_css("[data-testid='my-contacts-row']", text: "Ulrika User", wait: 8)
      end

      visit contacts_path
      capture_guide_image("my-contacts-panel", as: "story/ulrika_my_contacts")

      visit blog_posts_path(category_id: BlogCategory.find_by!(name: "Science").id)
      capture_guide_image("browse-preview", as: "story/ulrika_blog_posts")

      visit events_by_month_path(month: 11)
      capture_guide_image("event-list", as: "story/ulrika_events_by_month")

      visit people_path
      capture_guide_image(%w[classification-nav people-table], as: "story/ulrika_people")
    end

    it "Captures Ulrika's settings" do
      sign_in_and_wait(world.ulrika)
      visit preferences_settings_path
      capture_guide_image("preferences-panel", as: "story/ulrika_preferences")

      visit occasions_settings_path
      capture_guide_image("occasions-settings-panel", as: "story/ulrika_occasions_settings")
    end
  end
end
