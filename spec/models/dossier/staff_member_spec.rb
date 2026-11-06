# spec/models/dossier/staff_member_spec.rb
require "rails_helper"

RSpec.describe Dossier::StaffMember, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:position).of_type(:string) }
    it { is_expected.to have_db_column(:mobile).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:linkedin_url).of_type(:string) }
    it { is_expected.to have_db_column(:comment).of_type(:text) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:assignment_partner) }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is valid with a name and every optional detail" do
      member = build(:dossier_staff_member, name: "Priya Patel", position: "Delivery Lead", mobile: "+61 400 111 222",
                                            email: "priya@pwc.example", linkedin_url: "https://linkedin.com/in/priya",
                                            comment: "Owns the release plan")

      expect(member).to be_valid
      expect(member.to_toast_label).to eq("Priya Patel")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a name and takes only a valid email and an http(s) LinkedIn" do
      expect(build(:dossier_staff_member, name: " ")).not_to be_valid
      expect(build(:dossier_staff_member, email: "priya-at-pwc")).not_to be_valid
      expect(build(:dossier_staff_member, linkedin_url: "linkedin.com/in/priya")).not_to be_valid
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lists a Vendor's or Customer's Staff by name" do
      partner = create(:dossier_assignment_partner, :customer)
      zoe = create(:dossier_staff_member, assignment_partner: partner, name: "Zoe")
      adam = create(:dossier_staff_member, assignment_partner: partner, name: "adam")

      expect(partner.staff_members).to eq([ adam, zoe ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Strips text and blanks empty optional fields" do
      member = create(:dossier_staff_member, name: "  Priya  ", position: " ", email: "")

      expect(member).to have_attributes(name: "Priya", position: nil, email: nil)
    end

    it "Goes with its Vendor or Customer link, and with its Assignment" do
      first = create(:dossier_staff_member)
      second = create(:dossier_staff_member)

      expect { first.assignment_partner.destroy! }.to change(described_class, :count).by(-1)
      expect { second.assignment_partner.assignment.destroy! }.to change(described_class, :count).by(-1)
    end
  end
end
