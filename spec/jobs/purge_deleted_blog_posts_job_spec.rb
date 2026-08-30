# spec/jobs/purge_deleted_blog_posts_job_spec.rb
require "rails_helper"

RSpec.describe PurgeDeletedBlogPostsJob, type: :job do
  let(:owner) { create(:user, :content_creator) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Permanently destroys a post discarded more than 30 days ago" do
      post = create(:blog_post, user: owner, deleted_at: 31.days.ago)
      described_class.perform_now
      expect(BlogPost.exists?(post.id)).to be false
    end

    it "Destroys dependent blog_post_authors along with the post" do
      post = create(:blog_post, user: owner, deleted_at: 31.days.ago)
      author_id = post.blog_post_authors.first.id
      described_class.perform_now
      expect(BlogPostAuthor.exists?(author_id)).to be false
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Leaves a post discarded less than 30 days ago untouched" do
      post = create(:blog_post, user: owner, deleted_at: 1.day.ago)
      described_class.perform_now
      expect(BlogPost.exists?(post.id)).to be true
    end

    it "Leaves a kept (never deleted) post untouched regardless of age" do
      post = create(:blog_post, user: owner, created_at: 1.year.ago)
      described_class.perform_now
      expect(BlogPost.exists?(post.id)).to be true
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Destroys multiple eligible posts in one run" do
      create(:blog_post, user: owner, deleted_at: 40.days.ago)
      create(:blog_post, user: create(:user, :content_creator), deleted_at: 35.days.ago)
      described_class.perform_now
      expect(BlogPost.discarded.count).to eq(0)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Treats a post discarded exactly 30 days ago as not yet eligible" do
      post = create(:blog_post, user: owner, deleted_at: 30.days.ago + 1.minute)
      described_class.perform_now
      expect(BlogPost.exists?(post.id)).to be true
    end

    it "Does nothing when there are no discarded posts" do
      create(:blog_post, user: owner)
      expect { described_class.perform_now }.not_to change(BlogPost, :count)
    end
  end
end
