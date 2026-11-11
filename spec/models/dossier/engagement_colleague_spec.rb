# spec/models/dossier/engagement_colleague_spec.rb
require "rails_helper"

RSpec.describe Dossier::EngagementColleague, type: :model do
  let(:engagement) { create(:dossier_engagement) }
  let(:anna) { create(:person, first_name: "Anna", last_name: "Andersson", work_email: "anna@example.com") }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:engagement_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:person_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:position).of_type(:string) }
    it { is_expected.to have_db_column(:comment).of_type(:text) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:engagement) }
    it { is_expected.to belong_to(:person) }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Links a Person to the Engagement, with a position and comment of its own" do
      colleague = described_class.create!(engagement: engagement, person: anna, position: "Consultant",
                                          comment: "On the bench together")

      expect(colleague).to have_attributes(name: "Anna Andersson", to_toast_label: "Anna Andersson",
                                           work_email: "anna@example.com", position: "Consultant")
      expect(engagement.colleagues).to eq([ colleague ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a Person" do
      expect(described_class.new(engagement: engagement)).not_to be_valid
    end

    it "Won't link the same Person to the Engagement twice" do
      create(:dossier_engagement_colleague, engagement: engagement, person: anna)
      again = build(:dossier_engagement_colleague, engagement: engagement, person: anna)

      expect(again).not_to be_valid
      expect(again.errors[:person]).to include("is already a Colleague on this Engagement")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lists an Engagement's Colleagues by name" do
      zoe = create(:dossier_engagement_colleague, engagement: engagement, name: "Zoe Zed")
      adam = create(:dossier_engagement_colleague, engagement: engagement, name: "adam Ant")

      expect(engagement.colleagues).to eq([ adam, zoe ])
    end

    it "Is the same Person on another Engagement, or an Assignment's Colleague too" do
      create(:dossier_engagement_colleague, person: anna)
      create(:dossier_engagement_colleague, person: anna)
      create(:dossier_colleague, person: anna)

      expect(anna.dossier_engagement_colleagues.count).to eq(2)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Goes with its Engagement, leaving the Person" do
      create(:dossier_engagement_colleague, engagement: engagement, person: anna)

      expect { engagement.destroy! }.to change(described_class, :count).by(-1)
      expect(Person.exists?(anna.id)).to be(true)
    end

    it "Keeps its Person from being deleted" do
      create(:dossier_engagement_colleague, person: anna)

      expect(anna.destroy).to be(false)
      expect(anna.errors[:base]).to include("Anna Andersson is a Colleague or Staff member in Dossier: remove them there first.")
    end
  end
end
