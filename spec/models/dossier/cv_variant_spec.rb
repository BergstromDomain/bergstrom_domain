# spec/models/dossier/cv_variant_spec.rb
require "rails_helper"

RSpec.describe Dossier::CvVariant, type: :model do
  let(:charlie) { create(:user, :content_creator) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:target_company).of_type(:string) }
    it { is_expected.to have_db_column(:target_role).of_type(:string) }
    it { is_expected.to have_db_column(:job_description).of_type(:text) }
    it { is_expected.to have_db_column(:voice).of_type(:string).with_options(null: false, default: "first_person") }
    it { is_expected.to have_db_column(:style).of_type(:string).with_options(null: false, default: "classic") }
    it { is_expected.to have_db_column(:summary_override).of_type(:text) }
    it { is_expected.to have_db_column(:show_tech_stack).of_type(:boolean).with_options(null: false, default: false) }
    it { is_expected.to have_db_column(:min_importance).of_type(:integer).with_options(null: false, default: 3) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:based_on).class_name("Dossier::CvVariant").optional }
    it { is_expected.to have_many(:items).class_name("Dossier::CvVariantItem").dependent(:delete_all) }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is valid with a name, and defaults to first person, Classic, no Tech Stack and importance 3" do
      variant = create(:dossier_cv_variant, user: charlie, name: "QE Lead — Acme")

      expect(variant).to have_attributes(voice: "first_person", style: "classic", show_tech_stack: false,
                                         min_importance: 3, classification: "restricted")
      expect(variant.to_toast_label).to eq("QE Lead — Acme")
    end

    it "Uses the summary override, or else the Profile summary in its voice" do
      create(:dossier_profile, user: charlie, summary: "Test lead.", summary_third_person: "Alex leads tests.")
      variant = create(:dossier_cv_variant, user: charlie, voice: "third_person")

      expect(variant.summary).to eq("Alex leads tests.")
      variant.summary_override = "Tailored for Acme."
      expect(variant.summary).to eq("Tailored for Acme.")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a name, unique per user whatever the case" do
      create(:dossier_cv_variant, user: charlie, name: "Acme")

      expect(build(:dossier_cv_variant, user: charlie, name: "")).not_to be_valid
      expect(build(:dossier_cv_variant, user: charlie, name: "ACME").tap(&:valid?).errors[:name]).to include("has already been taken")
      expect(build(:dossier_cv_variant, name: "Acme")).to be_valid
    end

    it "Rejects an unknown voice or style, and an importance outside 1–5" do
      expect(build(:dossier_cv_variant, voice: "second_person")).not_to be_valid
      expect(build(:dossier_cv_variant, style: "modern")).not_to be_valid
      expect(build(:dossier_cv_variant, min_importance: 0)).not_to be_valid
      expect(build(:dossier_cv_variant, min_importance: 6)).not_to be_valid
    end

    it "Can't be based on another user's variant" do
      variant = build(:dossier_cv_variant, user: charlie, based_on: create(:dossier_cv_variant))

      expect(variant).not_to be_valid
      expect(variant.errors[:based_on]).to include("must be one of your CV Variants")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Copies another variant's settings and item rows, recording where it came from" do
      original = create(:dossier_cv_variant, user: charlie, name: "Acme", voice: "implied", show_tech_stack: true,
                                             min_importance: 4, target_role: "QE Lead", summary_override: "For Acme.")
      engagement = create(:dossier_engagement, user: charlie)
      original.items.create!(item: engagement, included: false)

      copy = described_class.copy_from(original, name: "Acme v2")
      copy.save!

      expect(copy).to have_attributes(user: charlie, based_on: original, voice: "implied", show_tech_stack: true,
                                       min_importance: 4, target_role: "QE Lead", summary_override: "For Acme.")
      expect(copy.items.map { |i| [ i.item, i.included ] }).to eq([ [ engagement, false ] ])
    end

    it "Keeps a copy when the variant it came from is deleted" do
      original = create(:dossier_cv_variant, user: charlie)
      copy = create(:dossier_cv_variant, user: charlie, based_on: original)

      original.destroy!

      expect(copy.reload.based_on).to be_nil
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Strips the name and blanks empty optional text" do
      variant = create(:dossier_cv_variant, name: "  Acme  ", target_company: " ", summary_override: "")

      expect(variant).to have_attributes(name: "Acme", target_company: nil, summary_override: nil)
    end

    it "Labels the voices" do
      expect(described_class::VOICES).to eq("first_person" => "First Person", "implied" => "Implied",
                                            "third_person" => "Third Person")
    end
  end
end
