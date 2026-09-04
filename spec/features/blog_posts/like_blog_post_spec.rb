# spec/features/blog_posts/like_blog_post_spec.rb

require "rails_helper"

RSpec.describe "Like blog post", type: :feature do
  let(:owner)  { create(:user, :content_creator) }
  let(:reader) { create(:user, :content_creator) }

  # :published already associates a blog_category (see spec/factories/blog_posts.rb)
  # and the factory default body is present — a stranger can only read a post
  # that's actually published (drafts are author-only regardless of classification).
  def published_post(**attrs)
    create(:blog_post, :unrestricted, :published, user: owner, **attrs)
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Defaults to neutral highlighted for a signed-in user who hasn't reacted" do
      post = published_post
      sign_in_as(reader)
      visit blog_post_path(post)

      expect(page).to have_selector("[data-testid='like-neutral'].like-button--active")
    end

    it "Highlights the clicked face and updates the score" do
      post = published_post
      sign_in_as(reader)
      visit blog_post_path(post)

      find("[data-testid='like-grinning']").click

      expect(page).to have_selector("[data-testid='like-grinning'].like-button--active")
      expect(page).not_to have_selector("[data-testid='like-neutral'].like-button--active")
      expect(post.reload.likes.find_by(user: reader).face).to eq("grinning")
    end

    it "Updates the highlight and score again when the user changes their reaction" do
      post = published_post
      sign_in_as(reader)
      visit blog_post_path(post)

      find("[data-testid='like-angry']").click
      find("[data-testid='like-slightly_smiling']").click

      expect(page).to have_selector("[data-testid='like-slightly_smiling'].like-button--active")
      expect(post.reload.likes.where(user: reader).count).to eq(1)
      expect(post.likes.find_by(user: reader).face).to eq("slightly_smiling")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page on a direct reaction request" do
      post = create(:blog_post, :unrestricted, user: owner)
      page.driver.submit :post, blog_post_like_path(post), { face: "grinning" }
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies a reaction to a post the user cannot read" do
      post = create(:blog_post, :restricted, user: owner)
      sign_in_as(reader)
      page.driver.submit :post, blog_post_like_path(post), { face: "grinning" }

      expect(page).to have_content("Not authorised")
      expect(post.reload.likes.where(user: reader)).to be_empty
    end

    it "Rejects a forged, invalid face value" do
      post = published_post
      sign_in_as(reader)
      page.driver.submit :post, blog_post_like_path(post), { face: "furious" }

      expect(page).to have_content("Invalid reaction")
      expect(post.reload.likes.where(user: reader)).to be_empty
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Shows the aggregate face highlighted (not neutral) to a guest, non-interactively" do
      post = published_post
      post.likes.create!(user: owner, face: "grinning")

      visit blog_post_path(post)

      expect(page).to have_selector("[data-testid='like-grinning'].like-button--active")
      expect(page).to have_selector("span.like-button--disabled[data-testid='like-grinning']")
      expect(page).not_to have_selector("button[data-testid^='like-']")
    end

    it "Lets an author react to their own post" do
      post = create(:blog_post, :unrestricted, user: owner)
      sign_in_as(owner)
      visit blog_post_path(post)
      find("[data-testid='like-slightly_frowning']").click

      expect(post.reload.likes.find_by(user: owner).face).to eq("slightly_frowning")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Computes the score correctly across several different reactors" do
      User.delete_all
      users = create_list(:user, 5, :content_creator)
      category = create(:blog_category)
      post = create(:blog_post, :unrestricted, :published,
        user: users.first, blog_category: category, body: "Content.")
      post.likes.create!(user: users[0], face: "grinning")
      post.likes.create!(user: users[1], face: "angry")
      post.likes.create!(user: users[2], face: "slightly_smiling")
      # users[3] and users[4] never react — implicit neutral (3) each.

      sign_in_as(users.last)
      visit blog_post_path(post)

      # (5 + 1 + 4 + 3 + 3) / 5 = 3.2
      expect(page).to have_selector("[data-testid='blog-post-likes-count']", text: "3.2")
    end
  end
end
