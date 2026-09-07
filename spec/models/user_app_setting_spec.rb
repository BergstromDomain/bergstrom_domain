# spec/models/user_app_setting_spec.rb
require "rails_helper"

RSpec.describe UserAppSetting, type: :model do
  subject { build(:user_app_setting) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:app_name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:start_page).of_type(:string) }
    it { is_expected.to have_db_column(:default_classification).of_type(:string).with_options(null: false, default: "restricted") }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it "belongs to a user" do
      setting = build(:user_app_setting)
      expect(setting.user).to be_a(User)
    end
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  describe ".display_name_for" do
    it "returns 'Occasions' for event_tracker" do
      expect(UserAppSetting.display_name_for("event_tracker")).to eq("Occasions")
    end

    it "returns 'Chronicle' for blog_posts" do
      expect(UserAppSetting.display_name_for("blog_posts")).to eq("Chronicle")
    end

    it "falls back to a humanized name for an app without a mapped display name" do
      expect(UserAppSetting.display_name_for("recipes")).to eq("Recipes")
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "validations" do
    # 1) Happy path ──────────────────────────────────────────────────────────
    describe "1) Happy path" do
      it "is valid with valid attributes" do
        expect(subject).to be_valid
      end

      it "defaults default_classification to restricted" do
        expect(UserAppSetting.new.default_classification).to eq("restricted")
      end

      %w[event_tracker blog_posts recipes photo_albums].each do |name|
        it "is valid with app_name '#{name}'" do
          subject.app_name = name
          expect(subject).to be_valid
        end
      end

      %w[restricted contacts unrestricted].each do |classification|
        it "is valid with default_classification '#{classification}'" do
          subject.default_classification = classification
          expect(subject).to be_valid
        end
      end

      it "is valid with a nil start_page" do
        subject.start_page = nil
        expect(subject).to be_valid
      end
    end

    # 2) Negative path ─────────────────────────────────────────────────────
    describe "2) Negative path" do
      it "is invalid without a user" do
        subject.user = nil
        expect(subject).not_to be_valid
      end

      it "is invalid without an app_name" do
        subject.app_name = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:app_name]).to include("can't be blank")
      end

      it "is invalid with an app_name outside the enum" do
        subject.app_name = "not_a_real_app"
        expect(subject).not_to be_valid
        expect(subject.errors[:app_name]).to be_present
      end

      it "is invalid with a default_classification outside the enum" do
        subject.default_classification = "not_a_real_classification"
        expect(subject).not_to be_valid
        expect(subject.errors[:default_classification]).to be_present
      end
    end

    # 3) Alternative path ──────────────────────────────────────────────────
    describe "3) Alternative path" do
      it "is invalid with a duplicate app_name for the same user" do
        user = create(:user)
        create(:user_app_setting, user: user, app_name: "event_tracker")
        duplicate = build(:user_app_setting, user: user, app_name: "event_tracker")

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:app_name]).to include("has already been taken")
      end

      it "is valid with the same app_name for different users" do
        user_a = create(:user)
        user_b = create(:user)
        create(:user_app_setting, user: user_a, app_name: "event_tracker")
        setting_b = build(:user_app_setting, user: user_b, app_name: "event_tracker")

        expect(setting_b).to be_valid
      end
    end

    # 4) Edge cases ─────────────────────────────────────────────────────────
    describe "4) Edge cases" do
      it "is valid with the same user having settings for multiple different apps" do
        user = create(:user)
        create(:user_app_setting, user: user, app_name: "event_tracker")
        other_app = build(:user_app_setting, user: user, app_name: "blog_posts")

        expect(other_app).to be_valid
      end
    end
  end
end
