# spec/models/concerns/likeable_spec.rb
require "rails_helper"

RSpec.describe Likeable, type: :model do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }

  # ── #current_user_face ────────────────────────────────────────────────────
  describe "#current_user_face" do
    # 1) Happy Path ─────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "returns the user's own explicit reaction" do
        post = create(:blog_post, user: owner)
        post.likes.create!(user: other, face: "angry")
        expect(post.current_user_face(other)).to eq("angry")
      end
    end

    # 3) Alternative Paths ────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "is nil when the user has never reacted" do
        post = create(:blog_post, user: owner)
        expect(post.current_user_face(other)).to be_nil
      end

      it "is nil for a nil (guest) user" do
        post = create(:blog_post, user: owner)
        expect(post.current_user_face(nil)).to be_nil
      end
    end

    # 4) Edge Cases ────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "is nil after the user's reaction has been cleared" do
        post = create(:blog_post, user: owner)
        like = post.likes.create!(user: other, face: "angry")
        like.clear!
        expect(post.current_user_face(other)).to be_nil
      end
    end
  end

  # ── #like_score / #like_score_face ────────────────────────────────────────
  describe "#like_score" do
    # 3) Alternative Paths ────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "reflects a single explicit reaction" do
        post = create(:blog_post, user: owner)
        post.likes.create!(user: other, face: "grinning")
        expect(post.like_score).to eq(5.0)
      end

      it "reflects multiple different explicit reactions, ignoring non-voters entirely" do
        users = create_list(:user, 3)
        post = create(:blog_post, user: owner)
        post.likes.create!(user: users[0], face: "grinning")
        post.likes.create!(user: users[1], face: "angry")
        post.likes.create!(user: users[2], face: "slightly_smiling")
        # (5 + 1 + 4) / 3 explicit reactors — User.count plays no part.
        expect(post.like_score).to eq(3.3333333333333335)
      end
    end

    # 4) Edge Cases ────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "is nil when nobody has explicitly reacted, regardless of user count" do
        create_list(:user, 5)
        post = create(:blog_post, user: owner)
        expect(post.like_score).to be_nil
      end

      it "ignores a cleared (nil-face) Like row" do
        post = create(:blog_post, user: owner)
        post.likes.create!(user: other, face: "grinning").clear!
        expect(post.like_score).to be_nil
      end
    end
  end

  describe "#like_score_face" do
    # 3) Alternative Paths ────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "rounds up at the midpoint, matching Ruby's default rounding" do
        post = build(:blog_post)
        allow(post).to receive(:like_score).and_return(2.5)
        expect(post.like_score_face).to eq("neutral")
      end

      it "maps a score of 3.2 to neutral" do
        post = build(:blog_post)
        allow(post).to receive(:like_score).and_return(3.2)
        expect(post.like_score_face).to eq("neutral")
      end

      it "maps a score of 4.6 to grinning" do
        post = build(:blog_post)
        allow(post).to receive(:like_score).and_return(4.6)
        expect(post.like_score_face).to eq("grinning")
      end

      it "maps a score of 1.0 to angry" do
        post = build(:blog_post)
        allow(post).to receive(:like_score).and_return(1.0)
        expect(post.like_score_face).to eq("angry")
      end
    end

    # 4) Edge Cases ────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "is nil when like_score is nil (no reactions yet)" do
        post = build(:blog_post)
        allow(post).to receive(:like_score).and_return(nil)
        expect(post.like_score_face).to be_nil
      end
    end
  end
end
