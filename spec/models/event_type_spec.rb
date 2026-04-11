# spec/models/event_type_spec.rb
require "rails_helper"

RSpec.describe EventType, type: :model do
  describe "database columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:icon).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  describe "validations" do
    subject { build(:event_type) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:icon) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_uniqueness_of(:icon) }

    context "when name differs only in case" do
      before { create(:event_type, name: "Music") }

      it "is invalid" do
        et = build(:event_type, name: "music")
        expect(et).not_to be_valid
        expect(et.errors[:name]).to include("has already been taken")
      end
    end

    context "when icon is already taken" do
      before { create(:event_type, icon: "music") }

      it "is invalid" do
        et = build(:event_type, icon: "music")
        expect(et).not_to be_valid
        expect(et.errors[:icon]).to include("has already been taken")
      end
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:events).dependent(:restrict_with_error) }
  end

  describe "FriendlyId" do
    it "generates a slug from name on create" do
      et = create(:event_type, name: "Work Experience")
      expect(et.slug).to eq("work-experience")
    end

    it "updates slug when name changes" do
      et = create(:event_type, name: "Birthday")
      et.update!(name: "Anniversary")
      et.reload
      expect(et.slug).to eq("anniversary")
    end

    it "finds record by slug" do
      et = create(:event_type, name: "Sport")
      expect(EventType.friendly.find("sport")).to eq(et)
    end
  end
end
