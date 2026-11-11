# spec/models/dossier/colleague_spec.rb
require "rails_helper"

RSpec.describe Dossier::Colleague, type: :model do
  let(:assignment) { create(:dossier_assignment) }
  let(:anna) { create(:person, first_name: "Anna", last_name: "Andersson", work_email: "anna@example.com") }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:person_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:position).of_type(:string) }
    it { is_expected.to have_db_column(:comment).of_type(:text) }
    it { is_expected.not_to have_db_column(:name) }
    it { is_expected.not_to have_db_column(:mobile) }
    it { is_expected.not_to have_db_column(:email) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to belong_to(:person) }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Links a Person and takes their name, Work Email and LinkedIn from them" do
      anna.update!(linkedin_url: "https://www.linkedin.com/in/anna-a")
      colleague = described_class.create!(assignment: assignment, person: anna, position: "Test Lead",
                                          comment: "Great at exploratory testing")

      expect(colleague).to have_attributes(name: "Anna Andersson", to_toast_label: "Anna Andersson",
                                           work_email: "anna@example.com",
                                           linkedin_url: "https://www.linkedin.com/in/anna-a")
    end

    it "Adds a new Person with the Colleague" do
      colleague = described_class.create!(assignment: assignment, position: "Developer",
                                          person_attributes: { first_name: "Bertil", last_name: "Berg",
                                                               user: assignment.user, classification: "restricted" })

      expect(colleague.person).to have_attributes(full_name: "Bertil Berg", classification: "restricted")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a Person" do
      colleague = described_class.new(assignment: assignment)

      expect(colleague).not_to be_valid
      expect(colleague.errors[:person]).to include("must exist")
    end

    it "Won't save a new Person with no first name" do
      colleague = described_class.new(assignment: assignment, person_attributes: { last_name: "Berg", user: assignment.user })

      expect(colleague).not_to be_valid
      expect(colleague.errors[:"person.first_name"]).to include("can't be blank")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lists an Assignment's Colleagues by name" do
      bertil = create(:dossier_colleague, assignment: assignment, name: "Bertil Berg")
      anna_colleague = create(:dossier_colleague, assignment: assignment, person: anna)

      expect(assignment.colleagues).to eq([ anna_colleague, bertil ])
    end

    it "Edits the linked Person's details through the Colleague" do
      colleague = create(:dossier_colleague, assignment: assignment, person: anna)
      colleague.update!(person_attributes: { work_email: "anna@work.example", linkedin_url: "linkedin.com/in/anna" })

      expect(anna.reload).to have_attributes(work_email: "anna@work.example", linkedin_url: "https://www.linkedin.com/in/anna")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Strips text and blanks empty optional fields" do
      colleague = create(:dossier_colleague, position: " ", comment: "  Ran UAT  ")

      expect(colleague).to have_attributes(position: nil, comment: "Ran UAT")
    end

    it "Goes with its Assignment, leaving the Person" do
      colleague = create(:dossier_colleague, person: anna)

      expect { colleague.assignment.destroy! }.to change(described_class, :count).by(-1)
      expect(Person.exists?(anna.id)).to be(true)
    end

    it "Is the same Person on several Assignments" do
      create(:dossier_colleague, person: anna)
      create(:dossier_colleague, person: anna)

      expect(anna.dossier_colleagues.count).to eq(2)
    end
  end
end
