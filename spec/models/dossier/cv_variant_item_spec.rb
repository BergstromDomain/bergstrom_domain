# spec/models/dossier/cv_variant_item_spec.rb
require "rails_helper"

RSpec.describe Dossier::CvVariantItem, type: :model do
  let(:variant) { create(:dossier_cv_variant) }

  describe "Associations" do
    it { is_expected.to belong_to(:cv_variant) }
    it { is_expected.to belong_to(:item) }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Ticks or unticks one Engagement, Assignment, Achievement, Skill or Credential" do
      skill = create(:dossier_skill)

      expect(variant.items.create!(item: skill, included: true)).to be_persisted
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Rejects other kinds of record" do
      item = variant.items.build(item: create(:dossier_organisation), included: true)

      expect(item).not_to be_valid
      expect(item.errors[:item_type]).to be_present
    end

    it "Holds one row per item" do
      skill = create(:dossier_skill)
      variant.items.create!(item: skill, included: true)

      expect(variant.items.build(item: skill, included: false)).not_to be_valid
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Can untick as well as tick" do
      expect(variant.items.create!(item: create(:dossier_skill), included: false).included).to be(false)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Goes when its variant is deleted" do
      variant.items.create!(item: create(:dossier_skill), included: true)

      expect { variant.destroy! }.to change(described_class, :count).by(-1)
    end

    it "Goes when the record it ticks is deleted" do
      engagement = create(:dossier_engagement, user: variant.user)
      variant.items.create!(item: engagement, included: true)

      expect { engagement.destroy! }.to change(described_class, :count).by(-1)
    end
  end
end
