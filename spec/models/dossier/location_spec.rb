# spec/models/dossier/location_spec.rb
require "rails_helper"

RSpec.describe Dossier::Location, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:city).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:country).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to have_many(:assignments).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:profiles).dependent(:nullify) }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is valid with a city and a country" do
      expect(build(:dossier_location, city: "Brisbane", country: "Australia")).to be_valid
    end

    it "Is named 'City, Country' in toasts and slugged on both" do
      location = create(:dossier_location, city: "Brisbane", country: "Australia")
      expect(location.name).to eq("Brisbane, Australia")
      expect(location.to_toast_label).to eq("Brisbane, Australia")
      expect(location.slug).to eq("brisbane-australia")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid without a city" do
      location = build(:dossier_location, city: "")
      expect(location).not_to be_valid
      expect(location.errors[:city]).to include("can't be blank")
    end

    it "Is invalid without a country" do
      location = build(:dossier_location, country: "")
      expect(location).not_to be_valid
      expect(location.errors[:country]).to include("can't be blank")
    end

    it "Is invalid when the same city and country already exist, in any case" do
      create(:dossier_location, city: "Brisbane", country: "Australia")
      location = build(:dossier_location, city: "brisbane", country: "AUSTRALIA")
      expect(location).not_to be_valid
      expect(location.errors[:city]).to include("has already been taken")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Allows the same city name in a different country" do
      create(:dossier_location, city: "Perth", country: "Australia")
      expect(build(:dossier_location, city: "Perth", country: "United Kingdom")).to be_valid
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Sorts by country, then city" do
      stockholm = create(:dossier_location, city: "Stockholm", country: "Sweden")
      brisbane  = create(:dossier_location, city: "Brisbane",  country: "Australia")
      falun     = create(:dossier_location, city: "Falun",     country: "Sweden")
      expect(described_class.alphabetical).to eq([ brisbane, falun, stockholm ])
    end

    it "Strips surrounding whitespace" do
      location = create(:dossier_location, city: " Falun ", country: " Sweden ")
      expect([ location.city, location.country ]).to eq([ "Falun", "Sweden" ])
    end
  end
end
