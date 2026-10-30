# spec/models/dossier/organisation_spec.rb
require "rails_helper"

RSpec.describe Dossier::Organisation, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:abbreviation).of_type(:string) }
    it { is_expected.to have_db_column(:industry_id).of_type(:integer) }
    it { is_expected.to have_db_column(:website_url).of_type(:string) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:industry).optional }
    it { is_expected.to have_many(:engagements).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:client_assignments).dependent(:restrict_with_error) }
  end

  it_behaves_like "Dossier named reference data", :dossier_organisation

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is valid with an abbreviation, an industry and a website" do
      organisation = build(:dossier_organisation,
        name: "Northwind Transport Authority", abbreviation: "NTA",
        industry: create(:dossier_industry, name: "Transport"),
        website_url: "https://northwind.example")
      expect(organisation).to be_valid
    end

    it "Shows the full name with its abbreviation as a label" do
      organisation = build(:dossier_organisation, name: "Northwind Transport Authority", abbreviation: "NTA")
      expect(organisation.label).to eq("Northwind Transport Authority (NTA)")
      expect(organisation.short_name).to eq("NTA")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid with a website that isn't an http(s) URL" do
      organisation = build(:dossier_organisation, website_url: "javascript:alert(1)")
      expect(organisation).not_to be_valid
      expect(organisation.errors[:website_url]).to include("must start with http:// or https://")
    end

    it "Is invalid with an abbreviation longer than 15 characters" do
      organisation = build(:dossier_organisation, abbreviation: "A" * 16)
      expect(organisation).not_to be_valid
      expect(organisation.errors[:abbreviation]).to be_present
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Uses the plain name when there is no abbreviation" do
      organisation = build(:dossier_organisation, name: "Contoso Retail", abbreviation: "")
      expect(organisation.label).to eq("Contoso Retail")
      expect(organisation.short_name).to eq("Contoso Retail")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Stores a blank abbreviation and website as nil" do
      organisation = create(:dossier_organisation, abbreviation: " ", website_url: "")
      expect([ organisation.abbreviation, organisation.website_url ]).to eq([ nil, nil ])
    end
  end
end
