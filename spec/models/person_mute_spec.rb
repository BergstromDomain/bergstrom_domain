# spec/models/person_mute_spec.rb
require "rails_helper"

RSpec.describe PersonMute, type: :model do
  let(:alice) { create(:user) }
  let(:bob)   { create(:user) }
  let(:adam)  { create(:person, user: alice) }
  let(:anna)  { create(:person, user: alice) }

  subject { build(:person_mute, user: alice, person: adam) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:person_id).of_type(:integer).with_options(null: false) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it "belongs to user" do
      mute = create(:person_mute, user: alice, person: adam)
      expect(mute.user).to eq(alice)
    end

    it "belongs to person" do
      mute = create(:person_mute, user: alice, person: adam)
      expect(mute.person).to eq(adam)
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "validations" do
    describe "happy path" do
      it "is valid with a user and a person" do
        expect(subject).to be_valid
      end
    end

    describe "negative path" do
      it "is invalid without a user" do
        subject.user = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:user]).to be_present
      end

      it "is invalid without a person" do
        subject.person = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:person]).to be_present
      end

      it "is invalid with a duplicate user/person pair" do
        create(:person_mute, user: alice, person: adam)
        duplicate = build(:person_mute, user: alice, person: adam)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:person_id]).to be_present
      end
    end

    describe "alternative path" do
      it "is valid for a different user to mute the same person" do
        create(:person_mute, user: alice, person: adam)
        other = build(:person_mute, user: bob, person: adam)
        expect(other).to be_valid
      end
    end

    describe "edge cases" do
      it "is valid for the same user to mute a different person" do
        create(:person_mute, user: alice, person: adam)
        other = build(:person_mute, user: alice, person: anna)
        expect(other).to be_valid
      end
    end
  end
end
