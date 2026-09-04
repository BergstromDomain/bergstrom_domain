# spec/features/blog_posts/deleted_blog_posts_spec.rb

require "rails_helper"

RSpec.describe "Deleted blog posts (admin restore)", type: :feature do
  let(:owner) { create(:user, :content_creator) }
  let(:admin) { create(:user, :admin) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Lists a deleted post with its author and days remaining" do
      post = create(:blog_post, user: owner, title: "Gone Post", deleted_at: 5.days.ago)
      sign_in_as(admin)
      visit deleted_blog_posts_path

      within("[data-testid='deleted-blog-post-row']") do
        expect(page).to have_link("Gone Post", href: blog_post_path(post))
        expect(page).to have_content(owner.first_name)
        expect(page).to have_content("25")
      end
    end

    it "Restores a post, making it visible and editable again" do
      post = create(:blog_post, user: owner, deleted_at: 5.days.ago)
      sign_in_as(admin)
      visit deleted_blog_posts_path
      find("[data-testid='restore-blog-post-#{post.id}']").click

      expect(page).to have_content("Blog post restored")
      expect(post.reload.deleted_at).to be_nil
    end

    it "No longer lists a post once it's been restored" do
      post = create(:blog_post, user: owner, title: "Restore Me", deleted_at: 5.days.ago)
      sign_in_as(admin)
      visit deleted_blog_posts_path
      find("[data-testid='restore-blog-post-#{post.id}']").click

      expect(page).not_to have_content("Restore Me")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Denies a content_creator access to the listing" do
      create(:blog_post, user: owner, deleted_at: 5.days.ago)
      sign_in_as(create(:user, :content_creator))
      visit deleted_blog_posts_path

      expect(page).to have_current_path(chronicle_path)
      expect(page).to have_content("Not authorised")
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit deleted_blog_posts_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies a direct restore request from a content_creator" do
      post = create(:blog_post, user: owner, deleted_at: 5.days.ago)
      sign_in_as(create(:user, :content_creator))

      page.driver.submit :post, restore_blog_post_path(post), {}

      expect(page).to have_content("Not authorised")
      expect(post.reload.deleted_at).to be_present
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Allows 'Sam SysAdmin' to view and restore" do
      post = create(:blog_post, user: owner, deleted_at: 5.days.ago)
      sign_in_as(create(:user, :system_admin))
      visit deleted_blog_posts_path

      find("[data-testid='restore-blog-post-#{post.id}']").click
      expect(post.reload.deleted_at).to be_nil
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Shows an empty state when nothing is deleted" do
      sign_in_as(admin)
      visit deleted_blog_posts_path

      expect(page).to have_selector("[data-testid='empty-state']")
      expect(page).not_to have_selector(".data-table")
    end

    it "Orders posts by most recently deleted first" do
      old_post = create(:blog_post, user: owner, title: "Old Delete", deleted_at: 10.days.ago)
      new_post = create(:blog_post, user: owner, title: "New Delete", deleted_at: 1.day.ago)
      sign_in_as(admin)
      visit deleted_blog_posts_path

      expect(page.text.index("New Delete")).to be < page.text.index("Old Delete")
    end
  end
end
