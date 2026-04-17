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
