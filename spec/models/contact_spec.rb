# spec/models/contact_spec.rb
require "rails_helper"

RSpec.describe Contact, type: :model do
  let(:alice) { create(:user) }
  let(:bob)   { create(:user) }

  subject { build(:contact, user: alice, contact: bob) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:contact_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:status).of_type(:string).with_options(null: false, default: "pending") }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it "belongs to user" do
        contact = create(:contact, user: alice, contact: bob)
        expect(contact.user).to eq(alice)
    end

    it "belongs to contact as a User" do
        contact = create(:contact, user: alice, contact: bob)
        expect(contact.contact).to eq(bob)
        expect(contact.contact).to be_a(User)
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "validations" do
    describe "happy path" do
      it "is valid with status pending" do
        subject.status = "pending"
        expect(subject).to be_valid
      end

      it "is valid with status confirmed" do
        subject.status = "confirmed"
        expect(subject).to be_valid
      end
    end

    describe "negative path" do
        it "is not valid without a user" do
            subject.user    = nil
            subject.user_id = nil
            expect(subject).not_to be_valid
            expect(subject.errors[:user]).to be_present
        end

      it "is invalid without a contact" do
        subject.contact = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:contact]).to be_present
      end

      it "is invalid with a duplicate user/contact pair" do
        create(:contact, user: alice, contact: bob)
        duplicate = build(:contact, user: alice, contact: bob)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:contact_id]).to be_present
      end

      it "is invalid with an unrecognised status" do
        subject.status = "blocked"
        expect(subject).not_to be_valid
        expect(subject.errors[:status]).to be_present
      end
    end

    describe "alternative path" do
      it "is valid when bob adds alice even if alice has already added bob" do
        create(:contact, user: alice, contact: bob)
        reverse = build(:contact, user: bob, contact: alice)
        expect(reverse).to be_valid
      end
    end

    describe "edge cases" do
      it "is invalid if a user tries to add themselves" do
        subject.contact = alice
        subject.user    = alice
        expect(subject).not_to be_valid
        expect(subject.errors[:contact_id]).to be_present
      end
    end
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  describe "scopes" do
    describe ".confirmed" do
      it "returns only confirmed contacts" do
        confirmed = create(:contact, user: alice, contact: bob, status: "confirmed")
        _pending  = create(:contact, user: bob, contact: alice, status: "pending")
        expect(Contact.confirmed).to contain_exactly(confirmed)
      end
    end
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  describe ".confirmed_between?" do
    it "returns true when alice has confirmed bob" do
      create(:contact, user: alice, contact: bob, status: "confirmed")
      expect(Contact.confirmed_between?(alice, bob)).to be true
    end

    it "returns true when bob has confirmed alice" do
      create(:contact, user: bob, contact: alice, status: "confirmed")
      expect(Contact.confirmed_between?(alice, bob)).to be true
    end

    it "returns false when the relationship is only pending" do
      create(:contact, user: alice, contact: bob, status: "pending")
      expect(Contact.confirmed_between?(alice, bob)).to be false
    end

    it "returns false when there is no relationship at all" do
      expect(Contact.confirmed_between?(alice, bob)).to be false
    end
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  describe ".confirmed_contact_ids_for" do
    it "returns the ids of confirmed contacts of the user" do
      create(:contact, user: alice, contact: bob, status: "confirmed")
      expect(Contact.confirmed_contact_ids_for(alice)).to include(bob.id)
    end

    it "includes contacts confirmed in either direction" do
      create(:contact, user: bob, contact: alice, status: "confirmed")
      expect(Contact.confirmed_contact_ids_for(alice)).to include(bob.id)
    end

    it "does not include pending contacts" do
      create(:contact, user: alice, contact: bob, status: "pending")
      expect(Contact.confirmed_contact_ids_for(alice)).not_to include(bob.id)
    end
  end
end
