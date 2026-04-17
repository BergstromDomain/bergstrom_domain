# spec/models/concerns/roleable_spec.rb
require "rails_helper"

RSpec.describe Roleable, type: :model do
  subject { build(:user) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:role).of_type(:string).with_options(null: false, default: "app_user") }
  end

  # ── Enum ──────────────────────────────────────────────────────────────────
  describe "enum" do
    it "defines app_user, content_creator, admin, and system_admin roles" do
      expect(User.roles.keys).to contain_exactly("app_user", "content_creator", "admin", "system_admin")
    end

    it "stores string values in the database" do
      expect(User.roles["app_user"]).to        eq("app_user")
      expect(User.roles["content_creator"]).to eq("content_creator")
      expect(User.roles["admin"]).to           eq("admin")
      expect(User.roles["system_admin"]).to    eq("system_admin")
    end

    it "does not define visitor as a stored role" do
      expect(User.roles).not_to include("visitor" => "visitor")
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "validations" do
    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "happy path" do
      context "role" do
        it "is valid with role app_user" do
          subject.role = "app_user"
          expect(subject).to be_valid
        end

        it "is valid with role content_creator" do
          subject.role = "content_creator"
          expect(subject).to be_valid
        end

        it "is valid with role admin" do
          subject.role = "admin"
          expect(subject).to be_valid
        end

        it "is valid with role system_admin" do
          subject.role = "system_admin"
          expect(subject).to be_valid
        end

        it "defaults to app_user" do
          expect(build(:user).role).to eq("app_user")
        end
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "negative path" do
      context "role" do
        it "is not valid with an unrecognised role" do
          subject.role = "superuser"
          expect(subject).not_to be_valid
          expect(subject.errors[:role]).to be_present
        end

        it "is not valid with a blank role" do
          subject.role = ""
          expect(subject).not_to be_valid
          expect(subject.errors[:role]).to be_present
        end
      end
    end

    # 3) Alternative path ─────────────────────────────────────────────────────
    describe "alternative path" do
      context "role" do
        it "retains the role when other attributes are updated" do
          user = create(:user, role: "content_creator")
          user.update!(email_address: "updated@example.com")
          expect(user.reload.role).to eq("content_creator")
        end
      end
    end

    # 4) Edge cases ───────────────────────────────────────────────────────────
    describe "edge cases" do
      context "role" do
        it "does not raise when reassigning the same role value" do
          subject.role = "app_user"
          expect { subject.role = "app_user" }.not_to raise_error
          expect(subject).to be_valid
        end
      end
    end
  end

  # ── Helper methods ────────────────────────────────────────────────────────
  describe "#can_administer?" do
    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "happy path" do
      it "returns true for admin" do
        subject.role = "admin"
        expect(subject.can_administer?).to be true
      end

      it "returns true for system_admin" do
        subject.role = "system_admin"
        expect(subject.can_administer?).to be true
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "negative path" do
      it "returns false for content_creator" do
        subject.role = "content_creator"
        expect(subject.can_administer?).to be false
      end

      it "returns false for app_user" do
        subject.role = "app_user"
        expect(subject.can_administer?).to be false
      end
    end
  end

  describe "#can_create_content?" do
    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "happy path" do
      it "returns true for content_creator" do
        subject.role = "content_creator"
        expect(subject.can_create_content?).to be true
      end

      it "returns true for admin" do
        subject.role = "admin"
        expect(subject.can_create_content?).to be true
      end

      it "returns true for system_admin" do
        subject.role = "system_admin"
        expect(subject.can_create_content?).to be true
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "negative path" do
      it "returns false for app_user" do
        subject.role = "app_user"
        expect(subject.can_create_content?).to be false
      end
    end
  end
end
