# spec/models/blog_category_spec.rb
require "rails_helper"

RSpec.describe BlogCategory, type: :model do
  subject { build(:blog_category) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:icon).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it { is_expected.to have_many(:blog_posts).dependent(:restrict_with_error) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "validations" do
    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "happy path" do
      it "is valid with all required fields" do
        bc = build(:blog_category, name: "Technology", icon: "cpu")
        expect(bc).to be_valid
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "negative path" do
      it "is invalid when name is blank" do
        bc = build(:blog_category, name: "")
        expect(bc).not_to be_valid
        expect(bc.errors[:name]).to include("can't be blank")
      end

      it "is invalid when name is a duplicate (same case)" do
        create(:blog_category, name: "Technology", icon: "cpu")
        bc = build(:blog_category, name: "Technology", icon: "server")
        expect(bc).not_to be_valid
        expect(bc.errors[:name]).to include("has already been taken")
      end

      it "is invalid when name is a duplicate (different case)" do
        create(:blog_category, name: "Technology", icon: "cpu")
        bc = build(:blog_category, name: "technology", icon: "server")
        expect(bc).not_to be_valid
        expect(bc.errors[:name]).to include("has already been taken")
      end

      it "is invalid when description is blank" do
        bc = build(:blog_category, description: "")
        expect(bc).not_to be_valid
        expect(bc.errors[:description]).to include("can't be blank")
      end

      it "is invalid when icon is blank" do
        bc = build(:blog_category, icon: "")
        expect(bc).not_to be_valid
        expect(bc.errors[:icon]).to include("can't be blank")
      end

      it "is invalid when icon is already taken by another record" do
        create(:blog_category, name: "Technology", icon: "cpu")
        bc = build(:blog_category, name: "Other", icon: "cpu")
        expect(bc).not_to be_valid
        expect(bc.errors[:icon]).to include("has already been taken")
      end

      it "is invalid when icon name is not in the Lucide icon set" do
        bc = build(:blog_category, icon: "not-a-real-icon")
        expect(bc).not_to be_valid
        expect(bc.errors[:icon]).to include("is not a valid Lucide icon name")
      end
    end

    # 3) Alternative path ─────────────────────────────────────────────────────
    describe "alternative path" do
      it "is valid when updating description without changing name" do
        bc = create(:blog_category, name: "Travel", icon: "plane")
        bc.description = "Updated description."
        expect(bc).to be_valid
      end
    end

    # 4) Edge cases ───────────────────────────────────────────────────────────
    describe "edge cases" do
      it "is invalid when icon has surrounding whitespace" do
        bc = build(:blog_category, icon: " cpu ")
        expect(bc).not_to be_valid
        expect(bc.errors[:icon]).to include("is not a valid Lucide icon name")
      end
    end
  end

  # ── FriendlyId ────────────────────────────────────────────────────────────
  describe "FriendlyId" do
    it "generates a slug from name on create" do
      bc = create(:blog_category, name: "Personal Finance", icon: "wallet")
      expect(bc.slug).to eq("personal-finance")
    end

    it "regenerates slug when name changes" do
      bc = create(:blog_category, name: "Travel", icon: "plane")
      bc.update!(name: "Adventures")
      bc.reload
      expect(bc.slug).to eq("adventures")
    end

    it "resolves the old slug after a name change" do
      bc = create(:blog_category, name: "Sport", icon: "trophy")
      bc.update!(name: "Athletics")
      expect(BlogCategory.friendly.find("sport")).to eq(bc)
    end
  end

  # ── Cascade behaviour ─────────────────────────────────────────────────────
  describe "restrict_with_error on delete" do
    it "prevents deletion when the category has associated blog posts" do
      category = create(:blog_category, name: "Technology", icon: "cpu")
      create(:blog_post, blog_category: category)
      expect { category.destroy }.not_to change(BlogCategory, :count)
      expect(category.errors[:base]).to include("Cannot delete record because dependent blog posts exist")
    end

    it "allows deletion when the category has no associated blog posts" do
      category = create(:blog_category, name: "Technology", icon: "cpu")
      expect { category.destroy }.to change(BlogCategory, :count).by(-1)
    end
  end
end
