# spec/models/user_spec.rb
require "rails_helper"

RSpec.describe User, type: :model do
  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:email_address).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:password_digest).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:role).of_type(:string).with_options(null: false, default: "app_user") }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_many(:contacts).dependent(:destroy) }
    it { is_expected.to have_many(:contact_users).through(:contacts).source(:contact) }
    it { is_expected.to have_many(:blog_posts) }
    it { is_expected.to have_many(:user_app_settings).dependent(:destroy) }
  end

  # ── #app_settings_for ────────────────────────────────────────────────────
  describe "#app_settings_for" do
    it "returns the existing UserAppSetting for that app" do
      user = create(:user)
      setting = create(:user_app_setting, user: user, app_name: "event_tracker")

      expect(user.app_settings_for("event_tracker")).to eq(setting)
    end

    it "returns a new unsaved UserAppSetting when none exists yet for that app" do
      user = create(:user)

      result = user.app_settings_for("blog_posts")

      expect(result).to be_a_new(UserAppSetting)
      expect(result.app_name).to eq("blog_posts")
    end
  end

  # ── Roleable ──────────────────────────────────────────────────────────────
  describe "Roleable concern" do
    subject { build(:user) }

    it "includes the Roleable concern" do
      expect(described_class.ancestors).to include(Roleable)
    end

    it "defaults to app_user" do
      expect(subject.role).to eq("app_user")
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "validations" do
    subject { build(:user) }

    # 1) Happy path
    # 2) Negative path
    # 3) Alternative path
    # 4) Edge cases
    # ... (existing validation specs unchanged)
  end
end
