# spec/features/guide_pages/story_world_spec.rb
require "rails_helper"

# Checks that the User Guide story's claims hold in the world its screenshots
# are taken in (spec/support/guide_story_world.rb). If one of these fails,
# the app has changed under the story: update the chapter, then re-take its
# screenshots with GUIDE_SCREENSHOTS=1.
RSpec.describe "User Guide story world", type: :feature do
  include ActiveSupport::Testing::TimeHelpers

  # Before the world is built (let! is a before hook too), so its dates are fixed.
  before { travel_to GuideStoryWorld::STORY_TIME }
  after  { travel_back }

  let!(:world) { build_story_world }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Shows Gary only Charlie's Unrestricted blog post" do
      visit blog_posts_path(category_id: BlogCategory.find_by!(name: "Science").id)

      within("[data-testid='main-content']") do
        expect(page).to have_content("Isaac Newton")
        expect(page).not_to have_content("Laws of Motion")
        expect(page).not_to have_content("Universal Gravitation")
      end
    end

    it "Shows Gary only Charlie's Unrestricted event in November" do
      visit events_by_month_path(month: 11)

      within("[data-testid='event-list']") do
        expect(page).to have_content("Ulrika's Birthday")
        expect(page).not_to have_content("Erik and Maja's Wedding")
        expect(page).not_to have_content("Maja's Birthday")
      end
    end

    it "Shows Gary only Charlie's Unrestricted recipe" do
      visit browse_by_cuisine_recipes_path(cuisine_id: Cuisine.find_by!(name: "Italian").id)
      expect(page).to have_css("[data-testid='browse-items-list']", text: "Charlie's Lasagna")

      visit browse_by_cuisine_recipes_path(cuisine_id: Cuisine.find_by!(name: "Swedish").id)
      expect(page).to have_css("[data-testid='empty-state']")
      expect(page).not_to have_content("Kanelbullar")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Shows Gary Ulrika's comment and the reactions, but nothing to add his own with" do
      visit blog_post_path(world.posts[:newton])

      within("[data-testid='comments-panel']") do
        expect(page).to have_content("Did the apple really fall on his head")
        expect(page).not_to have_field("comment[body]")
      end
      within("[data-testid='likes-panel']") do
        expect(page).to have_css("[data-testid='like-grinning'].like-button--disabled")
        expect(page).not_to have_button
      end
    end

    it "Gives Gary no way to create, edit or delete anything" do
      [ chronicle_path, cookbook_path, event_tracker_path ].each do |path|
        visit path
        expect(page).not_to have_css("[data-testid='left-nav-actions-h2']")
      end

      visit blog_post_path(world.posts[:newton])
      expect(page).not_to have_link("Edit")
      expect(page).not_to have_button("Delete")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Shows Charlie all three of their own posts" do
      sign_in_as(world.charlie)
      visit blog_posts_path(category_id: BlogCategory.find_by!(name: "Science").id)

      within("[data-testid='main-content']") do
        expect(page).to have_content("Isaac Newton")
        expect(page).to have_content("Laws of Motion")
        expect(page).to have_content("Universal Gravitation")
      end
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Leaves Gary's sign-up request pending, for Sam to review" do
      visit sign_up_path
      fill_in "First name", with: "Gary"
      fill_in "Last name", with: "Guest"
      attach_file "Profile image", Rails.root.join("docs/test-data/images/Test_User_Gary_Guest.png")
      fill_in "Email address", with: "gary@example.com"
      fill_in "Password", with: "password123"
      fill_in "Password confirmation", with: "password123"
      click_button "Sign Up"

      expect(page).to have_content("Your sign up request has been submitted.")
      expect(User.find_by!(email_address: "gary@example.com")).to have_attributes(status: "pending", role: "app_user")
    end
  end
end
