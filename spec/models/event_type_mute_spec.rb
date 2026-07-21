# spec/models/event_type_mute_spec.rb
require "rails_helper"

RSpec.describe EventTypeMute, type: :model do
  let(:alice)  { create(:user) }
  let(:bob)    { create(:user) }
  let(:sport)  { create(:event_type) }
  let(:music)  { create(:event_type) }

  subject { build(:event_type_mute, user: alice, event_type: sport) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:event_type_id).of_type(:integer).with_options(null: false) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it "belongs to user" do
      mute = create(:event_type_mute, user: alice, event_type: sport)
      expect(mute.user).to eq(alice)
    end

    it "belongs to event_type" do
      mute = create(:event_type_mute, user: alice, event_type: sport)
      expect(mute.event_type).to eq(sport)
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "validations" do
    describe "happy path" do
      it "is valid with a user and an event_type" do
        expect(subject).to be_valid
      end
    end

    describe "negative path" do
      it "is invalid without a user" do
        subject.user = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:user]).to be_present
      end

      it "is invalid without an event_type" do
        subject.event_type = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:event_type]).to be_present
      end

      it "is invalid with a duplicate user/event_type pair" do
        create(:event_type_mute, user: alice, event_type: sport)
        duplicate = build(:event_type_mute, user: alice, event_type: sport)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:event_type_id]).to be_present
      end
    end

    describe "alternative path" do
      it "is valid for a different user to mute the same event_type" do
        create(:event_type_mute, user: alice, event_type: sport)
        other = build(:event_type_mute, user: bob, event_type: sport)
        expect(other).to be_valid
      end
    end

    describe "edge cases" do
      it "is valid for the same user to mute a different event_type" do
        create(:event_type_mute, user: alice, event_type: sport)
        other = build(:event_type_mute, user: alice, event_type: music)
        expect(other).to be_valid
      end
    end
  end
end
