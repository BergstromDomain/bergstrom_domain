# spec/models/dossier/assignment_partner_spec.rb
require "rails_helper"

RSpec.describe Dossier::AssignmentPartner, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:kind).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:scope).of_type(:text) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to belong_to(:organisation).class_name("Dossier::Organisation") }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Links a Vendor with what they did" do
      pwc = create(:dossier_organisation, name: "PwC")
      vendor = create(:dossier_assignment_partner, kind: "vendor", organisation: pwc, scope: "Built the Salesforce portal")

      expect(vendor).to be_vendor
      expect(vendor.to_toast_label).to eq("PwC")
      expect(vendor.kind_label).to eq("Vendor")
    end

    it "Lists an Assignment's Vendors and Customers apart, by name" do
      assignment = create(:dossier_assignment)
      telstra = create(:dossier_assignment_partner, :customer, assignment: assignment,
                                                               organisation: create(:dossier_organisation, name: "Telstra"))
      pwc = create(:dossier_assignment_partner, assignment: assignment, organisation: create(:dossier_organisation, name: "PwC"))
      accenture = create(:dossier_assignment_partner, assignment: assignment,
                                                      organisation: create(:dossier_organisation, name: "Accenture"))

      expect(assignment.vendors).to eq([ accenture, pwc ])
      expect(assignment.customers).to eq([ telstra ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs an Organisation and a known kind" do
      expect(build(:dossier_assignment_partner, organisation: nil)).not_to be_valid
      expect { build(:dossier_assignment_partner, kind: "supplier") }.to raise_error(ArgumentError)
    end

    it "Holds an Organisation once per kind on an Assignment" do
      existing = create(:dossier_assignment_partner)
      duplicate = build(:dossier_assignment_partner, assignment: existing.assignment, organisation: existing.organisation)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:organisation_id]).to include("is already a Vendor on this Assignment")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lets the same Organisation be both Vendor and Customer" do
      existing = create(:dossier_assignment_partner)

      expect(build(:dossier_assignment_partner, :customer, assignment: existing.assignment,
                                                           organisation: existing.organisation)).to be_valid
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Blanks an empty scope and goes with its Assignment" do
      partner = create(:dossier_assignment_partner, scope: "  ")

      expect(partner.scope).to be_nil
      expect { partner.assignment.destroy! }.to change(described_class, :count).by(-1)
    end
  end
end
