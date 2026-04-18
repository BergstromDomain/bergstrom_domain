# spec/models/policy_spec.rb
require "rails_helper"

RSpec.describe Policy do
  # ── Helpers ───────────────────────────────────────────────────────────────
  let(:owner)           { create(:user, :content_creator) }
  let(:other_user)      { create(:user, :content_creator) }
  let(:app_user)        { create(:user) }
  let(:admin)           { create(:user, :admin) }
  let(:system_admin)    { create(:user, :system_admin) }
  let(:event_type)      { create(:event_type) }
  let(:person)          { create(:person) }

  let(:owned_event) do
    create(:event,
      title:          "Metallica - Master of Puppets",
      day:            27,
      month:          3,
      year:           1986,
      event_type:     event_type,
      people:         [ person ],
      user:           owner,
      classification: "unrestricted")
  end

  let(:contacts_event) do
    create(:event,
      title:          "Metallica - Ride the Lightning",
      day:            27,
      month:          7,
      year:           1984,
      event_type:     event_type,
      people:         [ person ],
      user:           owner,
      classification: "contacts")
  end

  let(:restricted_event) do
    create(:event,
      title:          "Metallica - Kill Em All",
      day:            25,
      month:          7,
      year:           1983,
      event_type:     event_type,
      people:         [ person ],
      user:           owner,
      classification: "restricted")
  end

  # ── can_read? ─────────────────────────────────────────────────────────────
  describe "#can_read?" do
    context "unrestricted content" do
      it "returns true for visitors (nil user)" do
        policy = Policy.new(nil, owned_event)
        expect(policy.can_read?).to be true
      end

      it "returns true for any authenticated user" do
        policy = Policy.new(app_user, owned_event)
        expect(policy.can_read?).to be true
      end
    end

    context "contacts content" do
      it "returns false for visitors" do
        policy = Policy.new(nil, contacts_event)
        expect(policy.can_read?).to be false
      end

      it "returns false for a user who is not a confirmed contact" do
        policy = Policy.new(other_user, contacts_event)
        expect(policy.can_read?).to be false
      end

      it "returns true for the owner" do
        policy = Policy.new(owner, contacts_event)
        expect(policy.can_read?).to be true
      end

      it "returns true for a confirmed contact of the owner" do
        Contact.create!(user: owner, contact: other_user, status: "confirmed")
        policy = Policy.new(other_user, contacts_event)
        expect(policy.can_read?).to be true
      end

      it "returns true for an admin" do
        policy = Policy.new(admin, contacts_event)
        expect(policy.can_read?).to be true
      end
    end

    context "restricted content" do
      it "returns false for visitors" do
        policy = Policy.new(nil, restricted_event)
        expect(policy.can_read?).to be false
      end

      it "returns false for an app_user who is not the owner" do
        policy = Policy.new(app_user, restricted_event)
        expect(policy.can_read?).to be false
      end

      it "returns true for the owner" do
        policy = Policy.new(owner, restricted_event)
        expect(policy.can_read?).to be true
      end

      it "returns true for an admin" do
        policy = Policy.new(admin, restricted_event)
        expect(policy.can_read?).to be true
      end
    end
  end

  # ── can_create? ───────────────────────────────────────────────────────────
  describe "#can_create?" do
    context "with no record (app symbol passed)" do
      it "returns false for a nil user" do
        policy = Policy.new(nil, :event_tracker)
        expect(policy.can_create?).to be false
      end

      it "returns false for an app_user" do
        policy = Policy.new(app_user, :event_tracker)
        expect(policy.can_create?).to be false
      end

      it "returns true for a content_creator" do
        policy = Policy.new(owner, :event_tracker)
        expect(policy.can_create?).to be true
      end

      it "returns true for an admin" do
        policy = Policy.new(admin, :event_tracker)
        expect(policy.can_create?).to be true
      end

      it "returns true for a system_admin" do
        policy = Policy.new(system_admin, :event_tracker)
        expect(policy.can_create?).to be true
      end
    end

    context "with an AppPermission override" do
      it "returns true for an app_user when override grants can_create" do
        create(:app_permission, user: app_user, app_name: "event_tracker", can_create: true)
        policy = Policy.new(app_user, :event_tracker)
        expect(policy.can_create?).to be true
      end

      it "returns false for a content_creator when override revokes can_create" do
        create(:app_permission, user: owner, app_name: "event_tracker", can_create: false)
        policy = Policy.new(owner, :event_tracker)
        expect(policy.can_create?).to be false
      end

      it "ignores overrides for system_admin — always true" do
        create(:app_permission, user: system_admin, app_name: "event_tracker", can_create: false)
        policy = Policy.new(system_admin, :event_tracker)
        expect(policy.can_create?).to be true
      end
    end
  end

  # ── can_update? ───────────────────────────────────────────────────────────
  describe "#can_update?" do
    context "role defaults, no override" do
      it "returns false for a nil user" do
        policy = Policy.new(nil, owned_event)
        expect(policy.can_update?).to be false
      end

      it "returns false for an app_user" do
        policy = Policy.new(app_user, owned_event)
        expect(policy.can_update?).to be false
      end

      it "returns true for the content_creator who owns the record" do
        policy = Policy.new(owner, owned_event)
        expect(policy.can_update?).to be true
      end

      it "returns false for a content_creator who does not own the record" do
        policy = Policy.new(other_user, owned_event)
        expect(policy.can_update?).to be false
      end

      it "returns true for an admin regardless of ownership" do
        policy = Policy.new(admin, owned_event)
        expect(policy.can_update?).to be true
      end

      it "returns true for a system_admin regardless of ownership" do
        policy = Policy.new(system_admin, owned_event)
        expect(policy.can_update?).to be true
      end

      it "returns false for a content_creator when resource is a symbol (no record)" do
        policy = Policy.new(owner, :event_tracker)
        expect(policy.can_update?).to be false
      end
    end

    context "with an AppPermission override" do
      it "returns true for an app_user when override grants can_update on own record" do
        create(:app_permission, user: app_user, app_name: "event_tracker", can_update: true)
        event = create(:event,
          title:      "Metallica - Black Album",
          day:        12,
          month:      8,
          year:       1991,
          event_type: event_type,
          people:     [ person ],
          user:       app_user,
          classification: "unrestricted")
        policy = Policy.new(app_user, event)
        expect(policy.can_update?).to be true
      end

      it "returns false for an admin when override revokes can_update" do
        create(:app_permission, user: admin, app_name: "event_tracker", can_update: false)
        policy = Policy.new(admin, owned_event)
        expect(policy.can_update?).to be false
      end

      it "ignores overrides for system_admin — always true" do
        create(:app_permission, user: system_admin, app_name: "event_tracker", can_update: false)
        policy = Policy.new(system_admin, owned_event)
        expect(policy.can_update?).to be true
      end
    end
  end

  # ── can_delete? ───────────────────────────────────────────────────────────
  describe "#can_delete?" do
    context "role defaults, no override" do
      it "returns false for a nil user" do
        policy = Policy.new(nil, owned_event)
        expect(policy.can_delete?).to be false
      end

      it "returns false for an app_user" do
        policy = Policy.new(app_user, owned_event)
        expect(policy.can_delete?).to be false
      end

      it "returns true for the content_creator who owns the record" do
        policy = Policy.new(owner, owned_event)
        expect(policy.can_delete?).to be true
      end

      it "returns false for a content_creator who does not own the record" do
        policy = Policy.new(other_user, owned_event)
        expect(policy.can_delete?).to be false
      end

      it "returns true for an admin regardless of ownership" do
        policy = Policy.new(admin, owned_event)
        expect(policy.can_delete?).to be true
      end

      it "returns true for a system_admin regardless of ownership" do
        policy = Policy.new(system_admin, owned_event)
        expect(policy.can_delete?).to be true
      end
    end

    context "with an AppPermission override" do
      it "returns true for a content_creator when override grants can_delete on another's record" do
        create(:app_permission, user: other_user, app_name: "event_tracker", can_delete: true)
        policy = Policy.new(other_user, owned_event)
        expect(policy.can_delete?).to be true
      end

      it "returns false for an admin when override revokes can_delete" do
        create(:app_permission, user: admin, app_name: "event_tracker", can_delete: false)
        policy = Policy.new(admin, owned_event)
        expect(policy.can_delete?).to be false
      end

      it "ignores overrides for system_admin — always true" do
        create(:app_permission, user: system_admin, app_name: "event_tracker", can_delete: false)
        policy = Policy.new(system_admin, owned_event)
        expect(policy.can_delete?).to be true
      end
    end
  end
end
