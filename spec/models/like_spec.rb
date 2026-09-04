# spec/models/like_spec.rb
require "rails_helper"

RSpec.describe Like, type: :model do
  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:face).of_type(:string).with_options(null: false, default: "neutral") }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it { is_expected.to belong_to(:blog_post) }
    it { is_expected.to belong_to(:user) }
  end

  # ── face enum ─────────────────────────────────────────────────────────────
  describe "face" do
    it {
      is_expected.to define_enum_for(:face).with_values(
        grinning: "grinning",
        slightly_smiling: "slightly_smiling",
        neutral: "neutral",
        slightly_frowning: "slightly_frowning",
        angry: "angry"
      ).backed_by_column_of_type(:string)
    }
  end

  # ── FACES mapping ─────────────────────────────────────────────────────────
  describe "FACES" do
    it "maps every face to a real Lucide icon name and a point value, grinning-to-angry" do
      expect(Like::FACES.keys).to eq(%w[grinning slightly_smiling neutral slightly_frowning angry])
      expect(Like::FACES.values.map { |data| data[:points] }).to eq([ 5, 4, 3, 2, 1 ])
    end
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "is valid with a blog_post, a user, and a face" do
      like = build(:like)
      expect(like).to be_valid
    end
  end

  # 2) Negative path ────────────────────────────────────────────────────────
  describe "negative path" do
    it "is invalid when the same user reacts to the same post twice" do
      post = create(:blog_post)
      user = create(:user)
      create(:like, blog_post: post, user: user)
      duplicate = build(:like, blog_post: post, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("has already been taken")
    end
  end

  # 3) Alternative path ─────────────────────────────────────────────────────
  describe "alternative path" do
    it "allows the same user to react to two different posts" do
      user = create(:user)
      create(:like, blog_post: create(:blog_post), user: user)
      second = build(:like, blog_post: create(:blog_post), user: user)
      expect(second).to be_valid
    end
  end

  # 4) Edge cases ────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "allows the same post to have multiple different reactors" do
      post = create(:blog_post)
      create(:like, blog_post: post, user: create(:user))
      second = build(:like, blog_post: post, user: create(:user))
      expect(second).to be_valid
    end
  end
end
