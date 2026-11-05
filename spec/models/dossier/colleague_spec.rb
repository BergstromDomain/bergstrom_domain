# spec/models/dossier/colleague_spec.rb
require "rails_helper"

RSpec.describe Dossier::Colleague, type: :model do
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
    it { is_expected.to belong_to(:assignment) }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is valid with a name and every optional detail" do
      colleague = build(:dossier_colleague, name: "Anna Andersson", position: "Test Lead", mobile: "+61 400 000 000",
                                            email: "anna@example.com", linkedin_url: "https://linkedin.com/in/anna",
                                            comment: "Great at exploratory testing")

      expect(colleague).to be_valid
      expect(colleague.to_toast_label).to eq("Anna Andersson")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a name" do
      expect(build(:dossier_colleague, name: " ")).not_to be_valid
    end

    it "Rejects a bad email or a LinkedIn that isn't an http(s) URL" do
      expect(build(:dossier_colleague, email: "anna-at-example")).not_to be_valid
      colleague = build(:dossier_colleague, linkedin_url: "linkedin.com/in/anna")
      expect(colleague).not_to be_valid
      expect(colleague.errors[:linkedin_url]).to include("must start with http:// or https://")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lists an Assignment's Colleagues by name" do
      assignment = create(:dossier_assignment)
      bertil = create(:dossier_colleague, assignment: assignment, name: "Bertil")
      anna = create(:dossier_colleague, assignment: assignment, name: "anna")

      expect(assignment.colleagues).to eq([ anna, bertil ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Strips text and blanks empty optional fields" do
      colleague = create(:dossier_colleague, name: "  Anna  ", position: " ", email: "", comment: "")

      expect(colleague).to have_attributes(name: "Anna", position: nil, email: nil, comment: nil)
    end

    it "Goes with its Assignment" do
      colleague = create(:dossier_colleague)

      expect { colleague.assignment.destroy! }.to change(described_class, :count).by(-1)
    end
  end
end
