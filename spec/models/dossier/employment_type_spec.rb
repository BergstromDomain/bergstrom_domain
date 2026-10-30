# spec/models/dossier/employment_type_spec.rb
require "rails_helper"

RSpec.describe Dossier::EmploymentType, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:permanent).of_type(:boolean).with_options(null: false, default: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  it_behaves_like "Dossier named reference data", :dossier_employment_type

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is not permanent by default" do
      expect(described_class.new.permanent).to be(false)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid with a nil permanent flag" do
      record = build(:dossier_employment_type, permanent: nil)
      expect(record).not_to be_valid
      expect(record.errors[:permanent]).to be_present
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Can be marked permanent" do
      expect(create(:dossier_employment_type, :permanent).permanent).to be(true)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Allows more than one permanent type" do
      create(:dossier_employment_type, :permanent, name: "Permanent Employment")
      expect(build(:dossier_employment_type, :permanent, name: "Fixed Term")).to be_valid
    end
  end
end
