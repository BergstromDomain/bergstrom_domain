# spec/models/blog_post_author_spec.rb
require "rails_helper"

RSpec.describe BlogPostAuthor, type: :model do
  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:blog_post) }
    it { is_expected.to belong_to(:user) }
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "Validations" do
    # 1) Happy Path ─────────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid with a blog_post and a user" do
        bpa = build(:blog_post_author)
        expect(bpa).to be_valid
      end
    end

    # 2) Negative Path ────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "is invalid when the same user is added twice to the same post" do
        post = create(:blog_post)
        user = create(:user)
        create(:blog_post_author, blog_post: post, user: user)
        duplicate = build(:blog_post_author, blog_post: post, user: user)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to include("has already been taken")
      end
    end

    # 3) Alternative Paths ─────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "allows the same user to co-author multiple different posts" do
        user = create(:user)
        post_one = create(:blog_post)
        post_two = create(:blog_post)
        create(:blog_post_author, blog_post: post_one, user: user)
        second = build(:blog_post_author, blog_post: post_two, user: user)
        expect(second).to be_valid
      end
    end

    # 4) Edge Cases ────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "allows the same post to have multiple different co-authors" do
        post = create(:blog_post)
        create(:blog_post_author, blog_post: post, user: create(:user))
        second = build(:blog_post_author, blog_post: post, user: create(:user))
        expect(second).to be_valid
      end
    end
  end
end
