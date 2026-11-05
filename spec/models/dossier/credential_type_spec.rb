# spec/models/dossier/credential_type_spec.rb
require "rails_helper"

RSpec.describe Dossier::CredentialType, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:position).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:training).of_type(:boolean).with_options(null: false, default: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to have_many(:credentials).dependent(:restrict_with_error) }
  end

  it_behaves_like "Dossier named reference data", :dossier_credential_type

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Sorts by position, then name" do
      course = create(:dossier_credential_type, name: "Course", position: 4)
      degree = create(:dossier_credential_type, name: "Degree", position: 1)
      award  = create(:dossier_credential_type, name: "Award", position: 4)
      expect(described_class.in_order).to eq([ degree, award, course ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid with a negative or fractional position" do
      expect(build(:dossier_credential_type, position: -1)).not_to be_valid
      expect(build(:dossier_credential_type, position: 1.5)).not_to be_valid
    end

    it "Is invalid with a nil training flag" do
      record = build(:dossier_credential_type, training: nil)
      expect(record).not_to be_valid
      expect(record.errors[:training]).to be_present
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Can be marked as training" do
      expect(create(:dossier_credential_type, :training)).to be_training
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Can't be deleted while a Credential uses it" do
      type = create(:dossier_credential_type)
      create(:dossier_credential, credential_type: type)
      expect(type.destroy).to be(false)
      expect(type.errors[:base]).to be_present
    end
  end
end
