# spec/models/dossier/role_spec.rb
require "rails_helper"

RSpec.describe Dossier::Role, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to have_many(:assignments).dependent(:restrict_with_error) }
  end

  it "Uses the dossier_ table prefix" do
    expect(described_class.table_name).to eq("dossier_roles")
  end

  it_behaves_like "Dossier named reference data", :dossier_role
end
