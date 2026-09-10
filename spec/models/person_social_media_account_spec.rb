# spec/models/person_social_media_account_spec.rb
require "rails_helper"

RSpec.describe PersonSocialMediaAccount, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:person_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:social_media_platform_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:username).of_type(:string).with_options(null: false) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:person) }
    it { is_expected.to belong_to(:social_media_platform) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "Validations" do
    # 1) Happy Path ───────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid with a person, platform and username" do
        account = build(:person_social_media_account)
        expect(account).to be_valid
      end

      it "is valid when the same platform is used by a different person" do
        platform = create(:social_media_platform)
        create(:person_social_media_account, social_media_platform: platform)
        account = build(:person_social_media_account, social_media_platform: platform)
        expect(account).to be_valid
      end

      it "is valid when the same person has accounts on different platforms" do
        person = create(:person)
        create(:person_social_media_account, person: person)
        account = build(:person_social_media_account, person: person)
        expect(account).to be_valid
      end
    end

    # 2) Negative Path ────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "is invalid when username is blank" do
        account = build(:person_social_media_account, username: "")
        expect(account).not_to be_valid
        expect(account.errors[:username]).to include("can't be blank")
      end

      it "is invalid when person already has an account on this platform" do
        person = create(:person)
        platform = create(:social_media_platform)
        create(:person_social_media_account, person: person, social_media_platform: platform)
        account = build(:person_social_media_account, person: person, social_media_platform: platform)
        expect(account).not_to be_valid
        expect(account.errors[:social_media_platform_id]).to include("has already been taken")
      end
    end

    # 3) Alternative Paths ─────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "is valid when updating the username" do
        account = create(:person_social_media_account, username: "old_handle")
        account.username = "new_handle"
        expect(account).to be_valid
      end
    end

    # 4) Edge Cases ───────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "allows re-adding the same platform after the previous account is removed" do
        person = create(:person)
        platform = create(:social_media_platform)
        existing = create(:person_social_media_account, person: person, social_media_platform: platform)
        existing.destroy
        account = build(:person_social_media_account, person: person, social_media_platform: platform)
        expect(account).to be_valid
      end
    end
  end
end
