# spec/models/dossier/credential_spec.rb
require "rails_helper"

RSpec.describe Dossier::Credential, type: :model do
  let(:user)       { create(:user, :content_creator) }
  let(:engagement) { create(:dossier_engagement, user: user) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:credential_type).of_type(:string).with_options(null: false, default: "course") }
    it { is_expected.to have_db_column(:hours).of_type(:decimal) }
    it { is_expected.to have_db_column(:classification).of_type(:string).with_options(null: false, default: "restricted") }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:provider).class_name("Dossier::Organisation").optional }
    it { is_expected.to belong_to(:engagement).optional }
    it { is_expected.to belong_to(:assignment).optional }
    it { is_expected.to have_many(:credential_skills).dependent(:destroy) }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is a Private course, tagged with Skills typed as text" do
      create(:dossier_skill, name: "Jira")
      course = create(:dossier_credential, user: user, skills_text: "jira, Excel VBA")

      expect(course).to have_attributes(credential_type: "course", classification: "restricted")
      expect(course.reload.skills_text).to eq("Jira, Excel VBA")
      expect(Dossier::Skill.find_by!(name: "Excel VBA").skill_category.name).to eq(Dossier::TechStack::UNCATEGORISED)
    end

    it "Takes its Engagement from its Assignment" do
      assignment = create(:dossier_assignment, engagement: engagement)
      course = create(:dossier_credential, user: user, assignment: assignment)
      expect(course.engagement).to eq(engagement)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid without a title or a start" do
      course = build(:dossier_credential, title: " ", start_on: nil)
      expect(course).not_to be_valid
      expect(course.errors.attribute_names).to include(:title, :start_month)
    end

    it "Is invalid under another user's Engagement" do
      course = build(:dossier_credential, user: user, engagement: create(:dossier_engagement))
      expect(course).not_to be_valid
      expect(course.errors[:engagement]).to include("must be one of your Engagements")
    end

    it "Is invalid with zero hours" do
      expect(build(:dossier_credential, hours: 0)).not_to be_valid
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Can stand alone, e.g. a course on the bench" do
      expect(create(:dossier_credential, user: user).engagement).to be_nil
    end

    it "Shows an unfinished course as in progress" do
      course = build(:dossier_credential, start_month: "2024-03", end_month: "")
      expect(course.dates).to eq("Mar 2024 – in progress")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Is hidden while its Engagement is deleted, and purged with it" do
      course = create(:dossier_credential, user: user, engagement: engagement)
      engagement.soft_delete!

      expect(course.reload).to be_hidden
      expect(described_class.kept).to be_empty
      engagement.destroy
      expect(described_class.exists?(course.id)).to be(false)
    end

    it "Stays with its Engagement when its Assignment is deleted" do
      assignment = create(:dossier_assignment, engagement: engagement)
      course = create(:dossier_credential, user: user, assignment: assignment)
      assignment.destroy

      expect(course.reload).to have_attributes(assignment_id: nil, engagement_id: engagement.id)
    end

    it "Shows a course within one month once" do
      expect(build(:dossier_credential, start_month: "2020-03", end_month: "2020-03").dates).to eq("Mar 2020")
    end
  end
end
