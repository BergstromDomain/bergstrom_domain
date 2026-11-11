# spec/models/dossier/staff_member_spec.rb
require "rails_helper"

RSpec.describe Dossier::StaffMember, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:person_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:position).of_type(:string) }
    it { is_expected.to have_db_column(:comment).of_type(:text) }
    it { is_expected.not_to have_db_column(:mobile) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:assignment_partner) }
    it { is_expected.to belong_to(:person) }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Links a Person, with a position and a comment of its own" do
      priya = create(:person, first_name: "Priya", last_name: "Patel", work_email: "priya@pwc.example")
      member = create(:dossier_staff_member, person: priya, position: "Delivery Lead", comment: "Owns the release plan")

      expect(member).to have_attributes(name: "Priya Patel", to_toast_label: "Priya Patel", work_email: "priya@pwc.example",
                                        position: "Delivery Lead", comment: "Owns the release plan")
      expect(member.assignment).to eq(member.assignment_partner.assignment)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a Person" do
      expect(build(:dossier_staff_member, person: nil)).not_to be_valid
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lists a Vendor's or Customer's Staff by name" do
      partner = create(:dossier_assignment_partner, :customer)
      zoe = create(:dossier_staff_member, assignment_partner: partner, name: "Zoe Zed")
      adam = create(:dossier_staff_member, assignment_partner: partner, name: "adam Ant")

      expect(partner.staff_members).to eq([ adam, zoe ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Goes with its Vendor or Customer link, and with its Assignment" do
      first = create(:dossier_staff_member)
      second = create(:dossier_staff_member)

      expect { first.assignment_partner.destroy! }.to change(described_class, :count).by(-1)
      expect { second.assignment_partner.assignment.destroy! }.to change(described_class, :count).by(-1)
    end
  end
end
