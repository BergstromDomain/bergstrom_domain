# spec/models/comment_spec.rb
require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:post) { create(:blog_post) }
  let(:user) { create(:user) }

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it { is_expected.to belong_to(:blog_post).counter_cache(true) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:parent).class_name("Comment").optional }
    it { is_expected.to have_many(:replies).class_name("Comment").dependent(:destroy) }
  end

  # ── Rich text ─────────────────────────────────────────────────────────────
  describe "rich text" do
    it "Stores body as Action Text rich text, not a plain column" do
      comment = create(:comment, blog_post: post, user: user, body: "<strong>Hi</strong>")
      expect(comment.body).to be_a(ActionText::RichText)
      expect(comment.body.to_s).to include("<strong>Hi</strong>")
    end
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "is valid as a top-level comment" do
      comment = build(:comment, blog_post: post, user: user, parent: nil)
      expect(comment).to be_valid
    end

    it "is valid as a reply to a top-level comment" do
      thread = create(:comment, blog_post: post, user: user)
      reply = build(:comment, blog_post: post, user: user, parent: thread)
      expect(reply).to be_valid
    end

    it "increments the blog post's comments_count" do
      expect { create(:comment, blog_post: post, user: user) }.to change { post.reload.comments_count }.by(1)
    end
  end

  # 2) Negative path ────────────────────────────────────────────────────────
  describe "negative path" do
    it "is invalid without a body" do
      comment = build(:comment, blog_post: post, user: user, body: nil)
      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to include("can't be blank")
    end

    it "is invalid without a user" do
      comment = build(:comment, blog_post: post, user: nil)
      expect(comment).not_to be_valid
    end

    it "is invalid when its parent is itself a reply (more than 2 levels deep)" do
      thread = create(:comment, blog_post: post, user: user)
      reply = create(:comment, blog_post: post, user: user, parent: thread)
      grandchild = build(:comment, blog_post: post, user: user, parent: reply)

      expect(grandchild).not_to be_valid
      expect(grandchild.errors[:parent]).to include("must be a top-level comment")
    end
  end

  # 3) Alternative path ─────────────────────────────────────────────────────
  describe "alternative path" do
    it "allows a different user to reply to someone else's comment" do
      thread = create(:comment, blog_post: post, user: user)
      other = create(:user)
      reply = build(:comment, blog_post: post, user: other, parent: thread)
      expect(reply).to be_valid
    end
  end

  # 4) Edge cases ────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "destroys all replies when the top-level comment is destroyed" do
      thread = create(:comment, blog_post: post, user: user)
      reply_one = create(:comment, blog_post: post, user: user, parent: thread)
      reply_two = create(:comment, blog_post: post, user: user, parent: thread)

      thread.destroy

      expect(Comment.exists?(reply_one.id)).to be false
      expect(Comment.exists?(reply_two.id)).to be false
    end

    it "decrements comments_count for the thread and each destroyed reply" do
      thread = create(:comment, blog_post: post, user: user)
      create(:comment, blog_post: post, user: user, parent: thread)
      create(:comment, blog_post: post, user: user, parent: thread)
      expect(post.reload.comments_count).to eq(3)

      thread.destroy

      expect(post.reload.comments_count).to eq(0)
    end

    it "orders replies oldest-first" do
      thread = create(:comment, blog_post: post, user: user)
      older = create(:comment, blog_post: post, user: user, parent: thread, created_at: 2.days.ago)
      newer = create(:comment, blog_post: post, user: user, parent: thread, created_at: 1.day.ago)

      expect(thread.reload.replies).to eq([ older, newer ])
    end
  end
end
