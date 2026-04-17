# spec/models/concerns/classifiable_spec.rb
require "rails_helper"

# The concern is tested through Event — the first model to include Classifiable.
RSpec.describe "Classifiable concern", type: :model do
  subject { build(:event) }

  # ── Enum ──────────────────────────────────────────────────────────────────
  describe "enum" do
    it "defines restricted, contacts, and unrestricted classifications" do
      expect(Event.classifications.keys).to contain_exactly("restricted", "contacts", "unrestricted")
    end

    it "stores string values in the database" do
      expect(Event.classifications["restricted"]).to eq("restricted")
      expect(Event.classifications["contacts"]).to eq("contacts")
      expect(Event.classifications["unrestricted"]).to eq("unrestricted")
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "validations" do
    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "happy path" do
      context "classification" do
        it "is valid with classification set to contacts" do
          subject.classification = "contacts"
          expect(subject).to be_valid
        end

        it "is valid with classification set to unrestricted" do
          subject.classification = "unrestricted"
          expect(subject).to be_valid
        end

        it "is valid with classification set to restricted" do
          subject.classification = "restricted"
          expect(subject).to be_valid
        end

        it "defaults to contacts" do
          expect(build(:event).classification).to eq("contacts")
        end
      end

      context "user" do
        it "is valid when a user is present" do
          subject.user = create(:user)
          expect(subject).to be_valid
        end
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "negative path" do
      context "classification" do
        it "is not valid without a classification" do
          subject.classification = nil
          expect(subject).not_to be_valid
          expect(subject.errors[:classification]).to be_present
        end

        it "is not valid when classification is set to an unrecognised value" do
          event = build(:event)
          event.classification = "top_secret"
          expect(event).not_to be_valid
          expect(event.errors[:classification]).to be_present
        end
      end

      context "user" do
        it "is not valid without a user" do
          subject.user = nil
          expect(subject).not_to be_valid
          expect(subject.errors[:user]).to be_present
        end
      end
    end

    # 3) Alternative path ─────────────────────────────────────────────────────
    describe "alternative path" do
      context "classification" do
        it "retains the classification when other attributes are updated" do
          event = create(:event, :restricted)
          event.update!(title: "Updated Title")
          expect(event.reload.classification).to eq("restricted")
        end
      end
    end

    # 4) Edge cases ───────────────────────────────────────────────────────────
    describe "edge cases" do
      context "classification" do
        it "does not raise when reassigning the same classification value" do
          subject.classification = "contacts"
          expect { subject.classification = "contacts" }.not_to raise_error
          expect(subject).to be_valid
        end
      end
    end
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  describe "scopes" do
    let!(:creator)            { create(:user) }
    let!(:unrestricted_event) { create(:event, :unrestricted, user: creator) }
    let!(:contacts_event)     { create(:event, :contacts,     user: creator) }
    let!(:restricted_event)   { create(:event, :restricted,   user: creator) }

    describe ".visible_to_visitors" do
      it "returns only unrestricted records" do
        expect(Event.visible_to_visitors).to contain_exactly(unrestricted_event)
      end

      it "excludes contacts records" do
        expect(Event.visible_to_visitors).not_to include(contacts_event)
      end

      it "excludes restricted records" do
        expect(Event.visible_to_visitors).not_to include(restricted_event)
      end
    end

    describe ".visible_to_users" do
      it "returns unrestricted and contacts records" do
        expect(Event.visible_to_users).to contain_exactly(unrestricted_event, contacts_event)
      end

      it "excludes restricted records" do
        expect(Event.visible_to_users).not_to include(restricted_event)
      end
    end

    describe ".visible_to_admins" do
      it "returns all records" do
        expect(Event.visible_to_admins).to contain_exactly(unrestricted_event, contacts_event, restricted_event)
      end
    end
  end
end
