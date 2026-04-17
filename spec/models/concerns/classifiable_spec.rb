# spec/models/concerns/classifiable_spec.rb
require "rails_helper"

RSpec.describe Classifiable, type: :model do
  let(:owner)       { create(:user) }
  let(:contact_user) { create(:user) }
  let(:stranger)    { create(:user) }

  before do
    create(:contact, user: owner, contact: contact_user, status: "confirmed")
  end

  let!(:unrestricted_event) { create(:event, :unrestricted, user: owner) }
  let!(:contacts_event)     { create(:event, :contacts,     user: owner) }
  let!(:restricted_event)   { create(:event, :restricted,   user: owner) }

  # ── visible_to_visitors ───────────────────────────────────────────────────
  describe ".visible_to_visitors" do
    it "returns only unrestricted events" do
      expect(Event.visible_to_visitors).to contain_exactly(unrestricted_event)
    end
  end

  # ── visible_to_users ──────────────────────────────────────────────────────
  describe ".visible_to_users" do
    describe "happy path" do
      it "returns unrestricted events to any user" do
        expect(Event.visible_to_users(stranger)).to include(unrestricted_event)
      end

      it "returns contacts events to a confirmed contact of the owner" do
        expect(Event.visible_to_users(contact_user)).to include(contacts_event)
      end

      it "returns contacts events to the owner" do
        expect(Event.visible_to_users(owner)).to include(contacts_event)
      end
    end

    describe "negative path" do
      it "does not return contacts events to a stranger" do
        expect(Event.visible_to_users(stranger)).not_to include(contacts_event)
      end

      it "does not return restricted events to any user" do
        expect(Event.visible_to_users(contact_user)).not_to include(restricted_event)
        expect(Event.visible_to_users(owner)).not_to include(restricted_event)
        expect(Event.visible_to_users(stranger)).not_to include(restricted_event)
      end
    end

    describe "alternative path" do
      it "can be chained with other scopes" do
        expect { Event.visible_to_users(contact_user).chronological }.not_to raise_error
      end
    end
  end

  # ── visible_to_admins ─────────────────────────────────────────────────────
  describe ".visible_to_admins" do
    it "returns all events" do
      expect(Event.visible_to_admins).to include(unrestricted_event, contacts_event, restricted_event)
    end
  end
end
