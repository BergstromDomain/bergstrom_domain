# spec/models/dossier/industry_spec.rb
require "rails_helper"

RSpec.describe Dossier::Industry, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to have_many(:organisations).dependent(:restrict_with_error) }

    it "Can't be deleted while an Organisation uses it" do
      industry = create(:dossier_industry)
      create(:dossier_organisation, industry: industry)
      expect(industry.destroy).to be(false)
      expect(industry.errors.full_messages.to_sentence).to match(/organisations/i)
    end
  end

  it "Uses the dossier_ table prefix" do
    expect(described_class.table_name).to eq("dossier_industries")
  end

  it_behaves_like "Dossier named reference data", :dossier_industry
end
