# spec/models/event_type_spec.rb
require "rails_helper"

RSpec.describe EventType, type: :model do
  subject { build(:event_type) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:icon).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it { is_expected.to have_many(:events).dependent(:restrict_with_error) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "validations" do
    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "happy path" do
      it "is valid with all required fields" do
        et = build(:event_type, name: "Music", icon: "music")
        expect(et).to be_valid
      end

      it "is valid when icon is a known Lucide icon name" do
        et = build(:event_type, icon: "cake")
        expect(et).to be_valid
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "negative path" do
      it "is invalid when name is blank" do
        et = build(:event_type, name: "")
        expect(et).not_to be_valid
        expect(et.errors[:name]).to include("can't be blank")
      end

      it "is invalid when name is a duplicate (same case)" do
        create(:event_type, name: "Music", icon: "music")
        et = build(:event_type, name: "Music", icon: "guitar")
        expect(et).not_to be_valid
        expect(et.errors[:name]).to include("has already been taken")
      end

      it "is invalid when name is a duplicate (different case)" do
        create(:event_type, name: "Music", icon: "music")
        et = build(:event_type, name: "music", icon: "guitar")
        expect(et).not_to be_valid
        expect(et.errors[:name]).to include("has already been taken")
      end

      it "is invalid when description is blank" do
        et = build(:event_type, description: "")
        expect(et).not_to be_valid
        expect(et.errors[:description]).to include("can't be blank")
      end

      it "is invalid when icon is blank" do
        et = build(:event_type, icon: "")
        expect(et).not_to be_valid
        expect(et.errors[:icon]).to include("can't be blank")
      end

      it "is invalid when icon is already taken by another record" do
        create(:event_type, name: "Music", icon: "music")
        et = build(:event_type, name: "Other", icon: "music")
        expect(et).not_to be_valid
        expect(et.errors[:icon]).to include("has already been taken")
      end

      it "is invalid when icon name is not in the Lucide icon set" do
        et = build(:event_type, icon: "not-a-real-icon")
        expect(et).not_to be_valid
        expect(et.errors[:icon]).to include("is not a valid Lucide icon name")
      end
    end

    # 3) Alternative path ─────────────────────────────────────────────────────
    describe "alternative path" do
      it "is valid when updating description without changing name" do
        et = create(:event_type, name: "Birthday", icon: "cake")
        et.description = "Updated description."
        expect(et).to be_valid
      end

      it "is valid when updating icon to a different known Lucide icon" do
        et = create(:event_type, name: "Sport", icon: "trophy")
        et.icon = "medal"
        expect(et).to be_valid
      end
    end

    # 4) Edge cases ───────────────────────────────────────────────────────────
    describe "edge cases" do
      it "is invalid when icon is a partial match of a real icon name" do
        et = build(:event_type, icon: "musi")
        expect(et).not_to be_valid
        expect(et.errors[:icon]).to include("is not a valid Lucide icon name")
      end

      it "is invalid when icon has surrounding whitespace" do
        et = build(:event_type, icon: " music ")
        expect(et).not_to be_valid
        expect(et.errors[:icon]).to include("is not a valid Lucide icon name")
      end
    end
  end

  # ── FriendlyId ────────────────────────────────────────────────────────────
  describe "FriendlyId" do
    it "generates a slug from name on create" do
      et = create(:event_type, name: "Work Experience", icon: "briefcase")
      expect(et.slug).to eq("work-experience")
    end

    it "regenerates slug when name changes" do
      et = create(:event_type, name: "Birthday", icon: "cake")
      et.update!(name: "Anniversary")
      et.reload
      expect(et.slug).to eq("anniversary")
    end

    it "resolves the old slug after a name change" do
      et = create(:event_type, name: "Sport", icon: "trophy")
      et.update!(name: "Athletics")
      expect(EventType.friendly.find("sport")).to eq(et)
    end

    it "finds a record by its current slug" do
      et = create(:event_type, name: "Music", icon: "music")
      expect(EventType.friendly.find("music")).to eq(et)
    end
  end

  # ── LUCIDE_VALID_ICONS ────────────────────────────────────────────────────
  describe "LUCIDE_VALID_ICONS" do
    it "is a non-empty Set" do
      expect(EventType::LUCIDE_VALID_ICONS).to be_a(Set)
      expect(EventType::LUCIDE_VALID_ICONS).not_to be_empty
    end

    it "includes known Lucide icon names" do
      expect(EventType::LUCIDE_VALID_ICONS).to include("music", "cake", "trophy")
    end

    it "does not include made-up names" do
      expect(EventType::LUCIDE_VALID_ICONS).not_to include("not-a-real-icon", "icon-1")
    end
  end

  # ── Cascade behaviour ─────────────────────────────────────────────────────
  describe "restrict_with_error on delete" do
    it "prevents deletion when the event type has associated events" do
      event_type = create(:event_type, name: "Music", icon: "music")
      create(:event, event_type: event_type)
      expect { event_type.destroy }.not_to change(EventType, :count)
      expect(event_type.errors[:base]).to include("Cannot delete record because dependent events exist")
    end

    it "allows deletion when the event type has no associated events" do
      event_type = create(:event_type, name: "Music", icon: "music")
      expect { event_type.destroy }.to change(EventType, :count).by(-1)
    end
  end
end
