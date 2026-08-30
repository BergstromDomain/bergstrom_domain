# spec/features/blog_posts/delete_blog_post_spec.rb

require "rails_helper"

RSpec.describe "Delete blog post", type: :feature do
  let(:owner) { create(:user, :content_creator) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Deletes a post and redirects to Chronicle" do
      post = create(:blog_post, user: owner, title: "My Post")
      sign_in_as(owner)
      visit blog_post_path(post)
      click_button "Delete"

      expect(page).to have_current_path(chronicle_path)
      expect(page).to have_content("Blog post deleted")
      expect(post.reload.deleted_at).to be_present
    end

    it "Is no longer visible to the author via its own show page after deletion" do
      post = create(:blog_post, :unrestricted, user: owner)
      sign_in_as(owner)
      visit blog_post_path(post)
      click_button "Delete"

      visit blog_post_path(post)
      expect(page).to have_current_path(chronicle_path)
      expect(page).to have_content("You do not have permission")
    end

    it "Deletes a published post the same way as a draft" do
      category = create(:blog_category)
      post = create(:blog_post, :published, user: owner, blog_category: category, body: "Content.")
      sign_in_as(owner)
      visit blog_post_path(post)
      click_button "Delete"

      expect(post.reload.deleted_at).to be_present
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Does not show the Delete button to a stranger" do
      post = create(:blog_post, :unrestricted, user: owner)
      sign_in_as(create(:user, :content_creator))
      visit blog_post_path(post)

      expect(page).not_to have_button("Delete")
    end

    it "Denies a direct delete request from a stranger" do
      post = create(:blog_post, :unrestricted, :published, user: owner, blog_category: create(:blog_category), body: "Content.")
      sign_in_as(create(:user, :content_creator))

      page.driver.submit :delete, blog_post_path(post), {}

      expect(page).to have_content("Not authorised")
      expect(post.reload.deleted_at).to be_nil
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      post = create(:blog_post, :unrestricted, user: owner)
      page.driver.submit :delete, blog_post_path(post), {}
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Allows a co-author (not the primary author) to delete" do
      post = create(:blog_post, user: owner)
      co_author = create(:user, :content_creator)
      post.blog_post_authors.create!(user: co_author)
      sign_in_as(co_author)

      visit blog_post_path(post)
      click_button "Delete"

      expect(post.reload.deleted_at).to be_present
    end

    it "Allows 'Adam Admin' to delete any post regardless of authorship" do
      post = create(:blog_post, user: owner)
      sign_in_as(create(:user, :admin))

      visit blog_post_path(post)
      click_button "Delete"

      expect(post.reload.deleted_at).to be_present
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Leaves blog_post_authors and the slug intact after a soft delete" do
      post = create(:blog_post, user: owner)
      co_author = create(:user, :content_creator)
      post.blog_post_authors.create!(user: co_author)
      sign_in_as(owner)

      visit blog_post_path(post)
      click_button "Delete"
      post.reload

      expect(post.authors).to contain_exactly(owner, co_author)
      expect(post.slug).to be_present
    end
  end
end
