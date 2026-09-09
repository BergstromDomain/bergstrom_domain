# spec/models/social_media_platform_spec.rb
require "rails_helper"

RSpec.describe SocialMediaPlatform, type: :model do
  subject { build(:social_media_platform) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:url).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to have_many(:person_social_media_accounts).dependent(:restrict_with_error) }
    it { is_expected.to have_one_attached(:logo) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "Validations" do
    # 1) Happy Path ───────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid with all required fields" do
        smp = build(:social_media_platform, name: "Facebook", url: "https://www.facebook.com/")
        expect(smp).to be_valid
      end

      it "is valid without a description" do
        smp = build(:social_media_platform, description: nil)
        expect(smp).to be_valid
      end

      it "is valid with an http URL" do
        smp = build(:social_media_platform, url: "http://example.com")
        expect(smp).to be_valid
      end

      it "is valid with a JPEG logo" do
        smp = build(:social_media_platform)
        smp.logo.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename:     "test_image.jpg",
          content_type: "image/jpeg"
        )
        expect(smp).to be_valid
      end

      it "is valid with a PNG logo" do
        smp = build(:social_media_platform)
        smp.logo.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
          filename:     "test_image.png",
          content_type: "image/png"
        )
        expect(smp).to be_valid
      end

      it "is valid with a WebP logo" do
        smp = build(:social_media_platform)
        smp.logo.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.webp")),
          filename:     "test_image.webp",
          content_type: "image/webp"
        )
        expect(smp).to be_valid
      end
    end

    # 2) Negative Path ────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "is invalid when name is blank" do
        smp = build(:social_media_platform, name: "")
        expect(smp).not_to be_valid
        expect(smp.errors[:name]).to include("can't be blank")
      end

      it "is invalid when name is a duplicate (same case)" do
        create(:social_media_platform, name: "Facebook")
        smp = build(:social_media_platform, name: "Facebook")
        expect(smp).not_to be_valid
        expect(smp.errors[:name]).to include("has already been taken")
      end

      it "is invalid when name is a duplicate (different case)" do
        create(:social_media_platform, name: "Facebook")
        smp = build(:social_media_platform, name: "facebook")
        expect(smp).not_to be_valid
        expect(smp.errors[:name]).to include("has already been taken")
      end

      it "is invalid when url is blank" do
        smp = build(:social_media_platform, url: "")
        expect(smp).not_to be_valid
        expect(smp.errors[:url]).to include("can't be blank")
      end

      it "is invalid when url has no scheme" do
        smp = build(:social_media_platform, url: "www.facebook.com")
        expect(smp).not_to be_valid
        expect(smp.errors[:url]).to include("must be a valid http(s) URL")
      end

      it "is invalid when url scheme is not http/https" do
        smp = build(:social_media_platform, url: "ftp://example.com")
        expect(smp).not_to be_valid
        expect(smp.errors[:url]).to include("must be a valid http(s) URL")
      end

      it "is invalid when url is not a parseable URI" do
        smp = build(:social_media_platform, url: "not a url")
        expect(smp).not_to be_valid
        expect(smp.errors[:url]).to include("must be a valid http(s) URL")
      end

      it "is invalid with a text file as logo" do
        smp = build(:social_media_platform)
        smp.logo.attach(
          io:           StringIO.new("not an image"),
          filename:     "not_an_image.txt",
          content_type: "text/plain"
        )
        expect(smp).not_to be_valid
        expect(smp.errors[:logo]).to be_present
      end

      it "is invalid with a GIF logo" do
        smp = build(:social_media_platform)
        smp.logo.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.gif")),
          filename:     "test_image.gif",
          content_type: "image/gif"
        )
        expect(smp).not_to be_valid
        expect(smp.errors[:logo]).to be_present
      end

      it "is invalid with a logo exceeding 5MB" do
        smp = build(:social_media_platform)
        smp.logo.attach(
          io:           StringIO.new("a" * 6.megabytes),
          filename:     "big.jpg",
          content_type: "image/jpeg"
        )
        expect(smp).not_to be_valid
        expect(smp.errors[:logo]).to be_present
      end
    end

    # 3) Alternative Paths ─────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "is valid when updating description without changing name" do
        smp = create(:social_media_platform, name: "Instagram")
        smp.description = "Updated description."
        expect(smp).to be_valid
      end

      it "is valid when updating url to a different valid URL" do
        smp = create(:social_media_platform, name: "Strava", url: "https://www.strava.com/")
        smp.url = "https://strava.com/"
        expect(smp).to be_valid
      end
    end

    # 4) Edge Cases ───────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "is invalid when url has surrounding whitespace and no scheme" do
        smp = build(:social_media_platform, url: " www.facebook.com ")
        expect(smp).not_to be_valid
        expect(smp.errors[:url]).to include("must be a valid http(s) URL")
      end
    end
  end

  # ── FriendlyId ────────────────────────────────────────────────────────────
  describe "FriendlyId" do
    it "generates a slug from name on create" do
      smp = create(:social_media_platform, name: "Strava Running")
      expect(smp.slug).to eq("strava-running")
    end

    it "regenerates slug when name changes" do
      smp = create(:social_media_platform, name: "Facebook")
      smp.update!(name: "Meta")
      smp.reload
      expect(smp.slug).to eq("meta")
    end

    it "resolves the old slug after a name change" do
      smp = create(:social_media_platform, name: "Twitter")
      smp.update!(name: "X")
      expect(SocialMediaPlatform.friendly.find("twitter")).to eq(smp)
    end

    it "finds a record by its current slug" do
      smp = create(:social_media_platform, name: "Facebook")
      expect(SocialMediaPlatform.friendly.find("facebook")).to eq(smp)
    end
  end

  # ── Cascade Behaviour ─────────────────────────────────────────────────────
  describe "Cascade Behaviour" do
    it "prevents deletion when the platform has associated person accounts" do
      platform = create(:social_media_platform)
      create(:person_social_media_account, social_media_platform: platform)
      expect { platform.destroy }.not_to change(SocialMediaPlatform, :count)
      expect(platform.errors[:base]).to include("Cannot delete record because dependent person social media accounts exist")
    end

    it "allows deletion when the platform has no associated person accounts" do
      platform = create(:social_media_platform)
      expect { platform.destroy }.to change(SocialMediaPlatform, :count).by(-1)
    end
  end

  describe "#to_toast_label" do
    it "Delegates to name" do
      smp = build(:social_media_platform)
      expect(smp.to_toast_label).to eq(smp.name)
    end
  end
end
