# spec/features/blog_posts/publish_blog_post_spec.rb

require "rails_helper"

RSpec.describe "Publish blog post", type: :feature do
  let(:owner)    { create(:user, :content_creator) }
  let(:category) { create(:blog_category, name: "Technology", icon: "cpu", description: "Tech posts.") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Publishes a complete draft and flips the button to Unpublish" do
      post = create(:blog_post, user: owner, blog_category: category, body: "Content.")
      sign_in_as(owner)
      visit blog_post_path(post)

      click_button "Publish"

      expect(page).to have_current_path(blog_post_path(post))
      expect(page).to have_content("Blog post published")
      expect(page).to have_button("Unpublish")
      expect(post.reload.published_at).to be_present
    end

    it "Unpublishes a published post and flips the button back to Publish" do
      post = create(:blog_post, :published, user: owner, blog_category: category, body: "Content.")
      sign_in_as(owner)
      visit blog_post_path(post)

      click_button "Unpublish"

      expect(page).to have_content("Blog post moved back to draft")
      expect(page).to have_button("Publish")
      expect(post.reload.published_at).to be_nil
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Shows an alert and does not publish when Category is missing" do
      post = create(:blog_post, user: owner, blog_category: nil, body: "Content.")
      sign_in_as(owner)
      visit blog_post_path(post)

      click_button "Publish"

      expect(page).to have_content("Cannot publish")
      expect(page).to have_content("Blog category can't be blank")
      expect(post.reload.published_at).to be_nil
    end

    it "Shows an alert and does not publish when body is missing" do
      post = create(:blog_post, user: owner, blog_category: category, body: nil)
      sign_in_as(owner)
      visit blog_post_path(post)

      click_button "Publish"

      expect(page).to have_content("Cannot publish")
      expect(page).to have_content("Body can't be blank")
      expect(post.reload.published_at).to be_nil
    end

    it "Does not show Publish/Unpublish buttons to a stranger" do
      post = create(:blog_post, :unrestricted, user: owner, blog_category: category, body: "Content.")
      sign_in_as(create(:user, :content_creator))
      visit blog_post_path(post)

      expect(page).not_to have_button("Publish")
      expect(page).not_to have_button("Unpublish")
    end

    it "Denies a direct publish request from a stranger" do
      post = create(:blog_post, :unrestricted, :published, user: owner, blog_category: category, body: "Content.")
      stranger = create(:user, :content_creator)
      sign_in_as(stranger)
      original_published_at = post.published_at

      page.driver.submit :post, publish_blog_post_path(post), {}

      expect(page).to have_content("Not authorised")
      expect(post.reload.published_at).to eq(original_published_at)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Allows a co-author (not the primary author) to publish" do
      post = create(:blog_post, user: owner, blog_category: category, body: "Content.")
      co_author = create(:user, :content_creator)
      post.blog_post_authors.create!(user: co_author)
      sign_in_as(co_author)

      visit blog_post_path(post)
      click_button "Publish"

      expect(post.reload.published_at).to be_present
    end

    it "Allows 'Adam Admin' to publish any post regardless of authorship" do
      post = create(:blog_post, user: owner, blog_category: category, body: "Content.")
      sign_in_as(create(:user, :admin))

      visit blog_post_path(post)
      click_button "Publish"

      expect(post.reload.published_at).to be_present
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Can be re-published after being unpublished" do
      post = create(:blog_post, :published, user: owner, blog_category: category, body: "Content.")
      sign_in_as(owner)
      visit blog_post_path(post)

      click_button "Unpublish"
      expect(post.reload.published_at).to be_nil

      click_button "Publish"
      expect(post.reload.published_at).to be_present
    end
  end
end
