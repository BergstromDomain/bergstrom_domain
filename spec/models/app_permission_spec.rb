# spec/models/app_permission_spec.rb
require "rails_helper"

RSpec.describe AppPermission, type: :model do
  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:app_name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:can_create).of_type(:boolean).with_options(null: false, default: false) }
    it { is_expected.to have_db_column(:can_update).of_type(:boolean).with_options(null: false, default: false) }
    it { is_expected.to have_db_column(:can_delete).of_type(:boolean).with_options(null: false, default: false) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it "belongs to a user" do
      permission = build(:app_permission)
      expect(permission.user).to be_a(User)
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "validations" do
    subject { build(:app_permission) }

    # 1) Happy path ──────────────────────────────────────────────────────────
    describe "1) Happy path" do
      context "with valid attributes" do
        it "is valid" do
          expect(subject).to be_valid
        end
      end

      context "with each valid app_name" do
        %w[event_tracker blog_posts recipes photo_albums].each do |name|
          it "is valid with app_name '#{name}'" do
            subject.app_name = name
            expect(subject).to be_valid
          end
        end
      end
    end

    # 2) Negative path ───────────────────────────────────────────────────────
    describe "2) Negative path" do
      context "without app_name" do
        it "is invalid" do
          subject.app_name = nil
          expect(subject).not_to be_valid
          expect(subject.errors[:app_name]).to include("can't be blank")
        end
      end

      context "with an invalid app_name" do
        it "is invalid" do
            subject.app_name = "invalid_app"
            expect(subject).not_to be_valid
            expect(subject.errors[:app_name]).to be_present
        end
    end

      context "with a duplicate app_name for the same user" do
        it "is invalid" do
          user = create(:user)
          create(:app_permission, user: user, app_name: "event_tracker")
          duplicate = build(:app_permission, user: user, app_name: "event_tracker")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:app_name]).to include("has already been taken")
        end
      end
    end

    # 3) Alternative path ────────────────────────────────────────────────────
    describe "3) Alternative path" do
      context "same app_name for different users" do
        it "is valid" do
          user_a = create(:user)
          user_b = create(:user)
          create(:app_permission, user: user_a, app_name: "event_tracker")
          permission_b = build(:app_permission, user: user_b, app_name: "event_tracker")
          expect(permission_b).to be_valid
        end
      end
    end

    # 4) Edge cases ──────────────────────────────────────────────────────────
    describe "4) Edge cases" do
      context "boolean columns default to false" do
        it "can_create defaults to false" do
          permission = create(:app_permission)
          expect(permission.can_create).to be false
        end

        it "can_update defaults to false" do
          permission = create(:app_permission)
          expect(permission.can_update).to be false
        end

        it "can_delete defaults to false" do
          permission = create(:app_permission)
          expect(permission.can_delete).to be false
        end
      end
    end
  end
end
