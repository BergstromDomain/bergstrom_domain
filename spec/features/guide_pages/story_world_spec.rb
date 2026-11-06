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

  def connect_ulrika_and_charlie
    create(:contact, user: world.ulrika, contact: world.charlie, status: "confirmed")
  end

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

    it "Lets Ulrika ask Charlie to connect, and Charlie accept" do
      sign_in_as(world.ulrika)
      visit contacts_path(q: "Charlie")
      find("[data-testid='connect-contact-#{world.charlie.id}']").click
      expect(page).to have_content("Request sent to Charlie Content Creator.")
      expect(page).to have_css("[data-testid='outgoing-pending-contact-row']", text: "Charlie Content Creator")
      click_button "Sign Out"

      sign_in_as(world.charlie)
      visit contacts_path
      request = Contact.find_by!(user: world.ulrika, contact: world.charlie)
      find("[data-testid='accept-contact-#{request.id}']").click
      expect(page).to have_css("[data-testid='my-contacts-row']", text: "Ulrika User")
    end

    it "Shows Ulrika, once connected to Charlie, their Contacts posts, events, people and recipes" do
      connect_ulrika_and_charlie
      sign_in_as(world.ulrika)

      visit blog_posts_path(category_id: BlogCategory.find_by!(name: "Science").id)
      within("[data-testid='browse-preview']") do
        expect(page).to have_content("Isaac Newton")
        expect(page).to have_content("Laws of Motion")
        expect(page).not_to have_content("Universal Gravitation")
      end

      visit events_by_month_path(month: 11)
      within("[data-testid='event-list']") do
        expect(page).to have_content("Ulrika's Birthday")
        expect(page).to have_content("Erik and Maja's Wedding")
        expect(page).not_to have_content("Maja's Birthday")
      end

      visit people_path
      within("[data-testid='people-table']") do
        expect(page).to have_content("Erik Lind")
        expect(page).not_to have_content("Maja Lind")
      end

      visit browse_by_cuisine_recipes_path(cuisine_id: Cuisine.find_by!(name: "Swedish").id)
      expect(page).to have_css("[data-testid='browse-items-list']", text: "Kanelbullar")
    end

    it "Lets Ulrika comment on and react to posts and recipes" do
      sign_in_as(world.ulrika)

      [ blog_post_path(world.posts[:newton]), recipe_path(world.recipes[:lasagna]) ].each do |path|
        visit path
        expect(page).to have_css("[data-testid='comments-panel'] [data-testid='comment-body-field']", visible: :all)
        expect(page).to have_css("[data-testid='likes-panel'] button[data-testid='like-grinning']")
      end
    end

    it "Gives Charlie Actions to create things in every app" do
      sign_in_as(world.charlie)

      { chronicle_path => "Create A Blog Post", cookbook_path => "Write A Recipe",
        event_tracker_path => "Create Event", dossier_path => "Create An Engagement" }.each do |path, link|
        visit path
        within("[data-testid='left-nav']") { expect(page).to have_link(link) }
      end
    end

    it "Keeps a deleted post for 30 days, for an admin to restore" do
      sign_in_as(world.charlie)
      visit blog_post_path(world.posts[:motion])
      click_button "Delete"
      expect(page).to have_content("The post can be restored by Admin for 30 days.")
      expect(world.posts[:motion].reload.deleted_at).to be_present
      click_button "Sign Out"

      sign_in_as(world.adam)
      visit deleted_blog_posts_path
      find("[data-testid='restore-blog-post-#{world.posts[:motion].id}']").click
      expect(world.posts[:motion].reload.deleted_at).to be_nil
    end

    it "Lets Charlie restore their own deleted Dossier engagement" do
      engagement = world.engagements[:observatory]
      engagement.soft_delete!
      sign_in_as(world.charlie)

      visit deleted_dossier_engagements_path
      find("[data-testid='restore-engagement-#{engagement.id}']").click
      expect(engagement.reload.deleted_at).to be_nil
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Shows Gary Ulrika's comment and the reactions, but nothing to add his own with" do
      visit blog_post_path(world.posts[:newton])

      within("[data-testid='comments-panel']") do
        expect(page).to have_content("Did the apple really fall on his head")
        expect(page).not_to have_css("[data-testid='comment-body-field']", visible: :all)
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

    it "Still gives Ulrika no way to create anything" do
      sign_in_as(world.ulrika)

      [ chronicle_path, cookbook_path, event_tracker_path ].each do |path|
        visit path
        expect(page).not_to have_css("[data-testid='left-nav-actions-h2']")
      end
    end

    it "Shows Ulrika nothing of Charlie's Contacts content until they're connected" do
      sign_in_as(world.ulrika)

      visit events_by_month_path(month: 11)
      within("[data-testid='event-list']") do
        expect(page).to have_content("Ulrika's Birthday")
        expect(page).not_to have_content("Erik and Maja's Wedding")
      end
    end

    it "Doesn't let Charlie add reference data, except Organisations and Skills in Dossier" do
      sign_in_as(world.charlie)

      { chronicle_path => "Create A Blog Category", event_tracker_path => "Create Event Type",
        cookbook_path => "Add A Cuisine" }.each do |path, link|
        visit path
        within("[data-testid='left-nav']") { expect(page).not_to have_link(link) }
      end

      visit dossier_path
      within("[data-testid='left-nav']") do
        expect(page).to have_link("Add An Organisation")
        expect(page).to have_link("Add A Skill")
        expect(page).not_to have_link("Add A Skill Category")
      end
    end

    it "Doesn't let Charlie restore their own deleted post" do
      world.posts[:motion].update!(deleted_at: Time.current)
      sign_in_as(world.charlie)

      visit deleted_blog_posts_path
      expect(page).not_to have_css("[data-testid='deleted-blog-post-table']")
    end

    it "Keeps Charlie's draft from everyone else, even a contact" do
      draft = create(:blog_post, :contacts, user: world.charlie, blog_category: world.posts[:newton].blog_category,
        title: "Optics", body: "Light and colour.")
      connect_ulrika_and_charlie
      sign_in_as(world.ulrika)

      visit blog_post_path(draft)
      expect(page).not_to have_css("[data-testid='blog-post-title']", text: "Optics")
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

    it "Lets Ulrika narrow People down to one visibility with the checkboxes" do
      connect_ulrika_and_charlie
      sign_in_as(world.ulrika)

      visit people_path(classifications: [ "contacts" ])
      within("[data-testid='people-table']") do
        expect(page).to have_content("Erik Lind")
        expect(page).not_to have_content("Ulrika User")
      end

      visit people_path(classifications: [ "unrestricted" ])
      within("[data-testid='people-table']") do
        expect(page).to have_content("Ulrika User")
        expect(page).not_to have_content("Erik Lind")
      end
    end

    it "Deletes an Occasions event for good, with no Deleted page to restore it from" do
      sign_in_as(world.charlie)
      visit event_path(world.events[:majas_birthday])
      click_button "Delete"

      expect(Event.exists?(world.events[:majas_birthday].id)).to be(false)
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

    it "Pre-ticks the People checkboxes from Ulrika's Default Visibility preference" do
      world.ulrika.update!(default_classifications: [ "unrestricted" ])
      sign_in_as(world.ulrika)

      visit people_path
      expect(page).to have_checked_field("classification_unrestricted")
      expect(page).to have_unchecked_field("classification_contacts")
    end

    it "Still hides Charlie's Restricted content from Ulrika after they connect" do
      connect_ulrika_and_charlie
      sign_in_as(world.ulrika)

      visit people_path(classifications: [ "restricted" ])
      expect(page).not_to have_content("Maja Lind")
    end

    it "Starts a new post at Charlie's default Chronicle visibility" do
      world.charlie.app_settings_for("blog_posts").update!(default_classification: "contacts")
      sign_in_as(world.charlie)

      visit new_blog_post_path
      expect(page).to have_select("blog_post[classification]", selected: "Contacts — visible to my contacts")
    end

    it "Deletes an event along with the only person in it, but keeps one that still has people" do
      sign_in_as(world.charlie)
      visit person_path(world.people[:maja])
      click_button "Delete"

      expect(Event.exists?(world.events[:majas_birthday].id)).to be(false)
      expect(world.events[:wedding].reload.people).to contain_exactly(world.people[:erik])
    end
  end
end
