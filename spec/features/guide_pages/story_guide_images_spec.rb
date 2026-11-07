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

  # ── Chapter 4: Charlie Creates ────────────────────────────────────────────
  describe "Charlie Content Creator" do
    before do
      sign_in_as(world.charlie)
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 8)
    end

    def capture_left_nav(path, as:)
      visit path
      page.execute_script("document.querySelector('[data-testid=\"left-nav\"]').style.height = 'auto'")
      capture_guide_image("left-nav", as: as)
    end

    it "Captures the left menus a Content Creator gets" do
      capture_left_nav(chronicle_path, as: "story/charlie_chronicle_left_nav")
      capture_left_nav(event_tracker_path, as: "story/charlie_occasions_left_nav")
      capture_left_nav(dossier_path, as: "story/charlie_dossier_left_nav")

      visit dossier_engagements_path
      capture_guide_image("timeline", as: "story/charlie_dossier_timeline")
    end

    it "Captures writing, publishing and deleting a blog post" do
      visit new_blog_post_path
      fill_in "Title", with: "Optics"
      select "Science", from: "blog_post[blog_category_id]"
      fill_in "blog_post[subject]", with: "Physics"
      fill_in "blog_post[topic]", with: "Isaac Newton"
      select "Contacts — visible to my contacts", from: "blog_post[classification]"
      capture_guide_image("new-panel-metadata", as: "story/charlie_post_form_visibility")

      click_button "Save Blog Post"
      expect(page).to have_content("Optics has been successfully created", wait: 8)
      visit blog_post_path(BlogPost.find_by!(title: "Optics"))
      expect(page).to have_css("[data-testid='draft-mode-warning']", wait: 8)
      capture_guide_image("draft-mode-warning", as: "story/charlie_draft_warning")
      capture_guide_image("show-panel-actions", as: "story/charlie_post_actions")

      js_click("delete-button")
      expect(page).to have_css("[data-testid='confirm-dialog'][open]", wait: 8)
      capture_guide_image("confirm-dialog-card", as: "story/charlie_delete_confirm")
      js_click("confirm-dialog-confirm")
      expect(page).to have_content("The post can be restored by Admin for 30 days.", wait: 8)
      capture_guide_image("toast-container", as: "story/charlie_post_deleted")
    end

    it "Captures restoring a deleted Dossier engagement" do
      world.engagements[:observatory].soft_delete!
      visit deleted_dossier_engagements_path
      capture_guide_image("deleted-engagement-table", as: "story/charlie_deleted_engagements")
    end

    it "Captures Charlie's app settings" do
      visit chronicle_settings_path
      capture_guide_image("chronicle-settings-panel", as: "story/charlie_chronicle_settings")
      visit cookbook_settings_path
      capture_guide_image("cookbook-settings-panel", as: "story/charlie_cookbook_settings")
    end
  end

  # ── Chapter 5: Adam Admin ─────────────────────────────────────────────────
  describe "Adam Admin" do
    before do
      sign_in_as(world.adam)
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 8)
    end

    it "Captures the left menu an admin gets, and every post in Science" do
      visit chronicle_path
      page.execute_script("document.querySelector('[data-testid=\"left-nav\"]').style.height = 'auto'")
      capture_guide_image("left-nav", as: "story/adam_chronicle_left_nav")

      visit blog_posts_path(category_id: BlogCategory.find_by!(name: "Science").id)
      capture_guide_image("browse-preview", as: "story/adam_blog_posts")
    end

    it "Captures adding a Blog Category, and refusing to delete one in use" do
      visit new_blog_category_path
      fill_in "blog_category[name]", with: "Astronomy"
      fill_in "blog_category[description]", with: "Stars, planets and the people who watch them."
      fill_in "blog_category[icon]", with: "telescope"
      capture_guide_image(%w[new-panel-main new-panel-metadata], as: "story/adam_blog_category_form")

      visit blog_category_path(BlogCategory.find_by!(name: "Science"))
      click_button "Delete Blog Category"
      expect(page).to have_css("[data-testid='confirm-dialog'][open]", wait: 8)
      js_click("confirm-dialog-confirm")
      expect(page).to have_css("[data-testid='toast-container']", wait: 8)
      capture_guide_image("toast-container", as: "story/adam_blog_category_in_use")
    end

    it "Captures restoring Charlie's deleted post" do
      charlie_deletes_optics(world)
      visit deleted_blog_posts_path
      capture_guide_image("deleted-blog-post-table", as: "story/adam_deleted_posts")
    end
  end

  # ── Sam's chapter (system admins only) ────────────────────────────────────
  describe "Sam SysAdmin" do
    let!(:gary) { gary_signs_up }

    before do
      sign_in_as(world.sam)
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 8)
    end

    it "Captures the System Admin menu and Gary's pending request" do
      open_dropdown("top-nav-system-admin")
      capture_guide_image(%w[top-nav top-nav-system-admin-menu], as: "system_admin/sam_system_admin_menu")

      visit system_admin_users_path(status: "pending")
      capture_guide_image(%w[user-list-filters user-list], as: "system_admin/sam_pending_users")

      visit system_admin_user_path(gary)
      capture_guide_image(%w[user-details-panel user-actions-panel], as: "system_admin/sam_gary_request")

      js_click("approve-button")
      expect(page).to have_content("Gary Guest has been approved.", wait: 8)
      capture_guide_image("user-details-panel", as: "system_admin/sam_gary_approved")
    end

    it "Captures changing Ulrika's role" do
      visit system_admin_user_path(world.ulrika)
      select "Content creator", from: "role"
      capture_guide_image("user-role-panel", as: "system_admin/sam_change_role")
    end
  end
end
