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

  # ── Logo ──────────────────────────────────────────────────────────────────
  describe "Logo" do
    let(:organisation) { create(:dossier_organisation) }

    def attach(io, filename) = organisation.logo.attach(io: io, filename: filename)

    it "Takes a JPEG, PNG or WebP logo" do
      organisation.logo.attach(file_fixture("test_image.png"))

      expect(organisation).to be_valid
      expect(organisation.logo).to be_attached
    end

    it "Refuses a GIF, an SVG, or text named .png" do
      { "logo.gif" => "GIF89a\x01\x00\x01\x00", "logo.svg" => "<svg xmlns='http://www.w3.org/2000/svg'/>",
        "logo.png" => "not an image" }.each do |filename, content|
        attach(StringIO.new(content), filename)

        expect(organisation).not_to be_valid
        expect(organisation.errors[:logo]).to include("must be a JPEG, PNG or WebP")
        organisation.logo.detach
      end
    end

    it "Refuses a logo of 2 MB or more" do
      attach(StringIO.new(file_fixture("test_image.jpg").binread + ("0" * 2.megabytes)), "big.jpg")

      expect(organisation).not_to be_valid
      expect(organisation.errors[:logo]).to include("must be smaller than 2 MB")
    end

    it "Fits its thumbnail within 160px, keeping the logo's shape" do
      organisation.logo.attach(file_fixture("test_image.png"))

      expect(organisation.logo.variant(:thumbnail).variation.transformations).to include(resize_to_limit: [ 160, 160 ])
    end

    it "Removes the logo when saved with Remove Logo ticked, and keeps it otherwise" do
      organisation.logo.attach(file_fixture("test_image.png"))
      organisation.update!(remove_logo: "0")
      expect(organisation.reload.logo).to be_attached

      organisation.update!(remove_logo: "1")
      expect(organisation.reload.logo).not_to be_attached
    end

    it "Goes with the Organisation" do
      organisation.logo.attach(file_fixture("test_image.png"))

      expect { organisation.destroy }.to change(ActiveStorage::Attachment, :count).by(-1)
    end
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:industry).optional }
    it { is_expected.to have_many(:engagements).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:client_assignments).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:products).class_name("Dossier::Skill").dependent(:restrict_with_error) }

    it "Can't be deleted while it's a Skill's vendor" do
      microsoft = create(:dossier_organisation, name: "Microsoft")
      create(:dossier_skill, name: "Project", vendor: microsoft)

      expect(microsoft.destroy).to be(false)
      expect(microsoft.errors.full_messages).to include("Cannot delete record because dependent products exist")
    end
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
