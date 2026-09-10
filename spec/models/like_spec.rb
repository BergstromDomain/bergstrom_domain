# spec/models/like_spec.rb
require "rails_helper"

RSpec.describe Like, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:face).of_type(:string).with_options(null: false, default: "neutral") }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:blog_post) }
    it { is_expected.to belong_to(:user) }
  end

  # ── Face ──────────────────────────────────────────────────────────────────
  describe "Face" do
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

  # ── Validations ───────────────────────────────────────────────────────────
  describe "Validations" do
    # 1) Happy Path ─────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid with a blog_post, a user, and a face" do
        like = build(:like)
        expect(like).to be_valid
      end
    end

    # 2) Negative Path ──────────────────────────────────────────────────────
    describe "Negative Path" do
      it "is invalid when the same user reacts to the same post twice" do
        post = create(:blog_post)
        user = create(:user)
        create(:like, blog_post: post, user: user)
        duplicate = build(:like, blog_post: post, user: user)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to include("has already been taken")
      end
    end

    # 3) Alternative Paths ──────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "allows the same user to react to two different posts" do
        user = create(:user)
        create(:like, blog_post: create(:blog_post), user: user)
        second = build(:like, blog_post: create(:blog_post), user: user)
        expect(second).to be_valid
      end
    end

    # 4) Edge Cases ──────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "allows the same post to have multiple different reactors" do
        post = create(:blog_post)
        create(:like, blog_post: post, user: create(:user))
        second = build(:like, blog_post: post, user: create(:user))
        expect(second).to be_valid
      end
    end
  end
end
