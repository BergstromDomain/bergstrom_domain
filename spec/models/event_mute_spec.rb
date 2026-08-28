# spec/models/event_mute_spec.rb
require "rails_helper"

RSpec.describe EventMute, type: :model do
  let(:alice)   { create(:user) }
  let(:bob)     { create(:user) }
  let(:wedding) { create(:event, user: alice) }
  let(:concert) { create(:event, user: alice) }

  subject { build(:event_mute, user: alice, event: wedding) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:event_id).of_type(:integer).with_options(null: false) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it "belongs to user" do
      mute = create(:event_mute, user: alice, event: wedding)
      expect(mute.user).to eq(alice)
    end

    it "belongs to event" do
      mute = create(:event_mute, user: alice, event: wedding)
      expect(mute.event).to eq(wedding)
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "validations" do
    describe "happy path" do
      it "is valid with a user and an event" do
        expect(subject).to be_valid
      end
    end

    describe "negative path" do
      it "is invalid without a user" do
        subject.user = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:user]).to be_present
      end

      it "is invalid without an event" do
        subject.event = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:event]).to be_present
      end

      it "is invalid with a duplicate user/event pair" do
        create(:event_mute, user: alice, event: wedding)
        duplicate = build(:event_mute, user: alice, event: wedding)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:event_id]).to be_present
      end
    end

    describe "alternative path" do
      it "is valid for a different user to mute the same event" do
        create(:event_mute, user: alice, event: wedding)
        other = build(:event_mute, user: bob, event: wedding)
        expect(other).to be_valid
      end
    end

    describe "edge cases" do
      it "is valid for the same user to mute a different event" do
        create(:event_mute, user: alice, event: wedding)
        other = build(:event_mute, user: alice, event: concert)
        expect(other).to be_valid
      end
    end
  end
end
