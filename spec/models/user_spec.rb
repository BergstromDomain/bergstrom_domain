# spec/models/user_spec.rb
require "rails_helper"

RSpec.describe User, type: :model do
  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:email_address).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:password_digest).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "validations" do
    subject { build(:user) }

    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "happy path" do
      it "is valid with valid attributes" do
        expect(subject).to be_valid
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "negative path" do
      it "is invalid without an email address" do
        subject.email_address = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:email_address]).to include("can't be blank")
      end

      it "is invalid with a duplicate email address" do
        create(:user, email_address: "bergstrom@example.com")
        subject.email_address = "bergstrom@example.com"
        expect(subject).not_to be_valid
        expect(subject.errors[:email_address]).to include("has already been taken")
      end

      it "is invalid with a malformed email address" do
        subject.email_address = "not-an-email"
        expect(subject).not_to be_valid
        expect(subject.errors[:email_address]).to be_present
      end

      it "is invalid without a password on create" do
        user = build(:user, password: nil, password_confirmation: nil)
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end
    end

    # 3) Alternative path ─────────────────────────────────────────────────────
    describe "alternative path" do
      it "normalises email address to lowercase" do
        user = create(:user, email_address: "BERGSTROM@EXAMPLE.COM")
        expect(user.reload.email_address).to eq("bergstrom@example.com")
      end

      it "normalises email address by stripping whitespace" do
        user = create(:user, email_address: "  bergstrom@example.com  ")
        expect(user.reload.email_address).to eq("bergstrom@example.com")
      end

      it "stores password_digest, not plaintext password" do
        user = create(:user)
        expect(user.password_digest).to be_present
        expect(user.password_digest).not_to eq(user.password)
      end

      it "authenticates with correct password" do
        user = create(:user, password: "secret123", password_confirmation: "secret123")
        expect(user.authenticate("secret123")).to eq(user)
      end

      it "does not authenticate with incorrect password" do
        user = create(:user, password: "secret123", password_confirmation: "secret123")
        expect(user.authenticate("wrong")).to be_falsy
      end
    end

    # 4) Edge cases ───────────────────────────────────────────────────────────
    describe "edge cases" do
      it "treats email addresses as case-insensitively unique" do
        create(:user, email_address: "bergstrom@example.com")
        duplicate = build(:user, email_address: "BERGSTROM@EXAMPLE.COM")
        expect(duplicate).not_to be_valid
      end

      it "is valid updating a record without changing the password" do
        user = create(:user)
        user.email_address = "updated@example.com"
        expect(user).to be_valid
      end
    end
  end
end
