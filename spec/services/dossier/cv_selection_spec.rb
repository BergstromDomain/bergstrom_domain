# spec/services/dossier/cv_selection_spec.rb

require "rails_helper"

RSpec.describe Dossier::CvSelection do
  let(:user)      { create(:user, :content_creator) }
  let(:today)     { Date.new(2026, 11, 6) }
  let(:variant)   { create(:dossier_cv_variant, user: user) }
  let(:selection) { described_class.new(variant, today: today) }

  def engagement(*traits, **attributes)
    create(:dossier_engagement, *traits, user: user, **attributes)
  end

  def assignment_in(engagement, **attributes)
    create(:dossier_assignment, engagement: engagement, **attributes)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows Engagements of the last 10 years in full" do
      recent = engagement(start_month: "2017-01", end_month: "2017-12")
      assignment = assignment_in(recent)

      expect(selection.included?(recent)).to be(true)
      expect(selection.included?(assignment)).to be(true)
    end

    it "Includes Achievements at or above the variant's minimum importance" do
      assignment = assignment_in(engagement(:current))
      high = create(:dossier_achievement, assignment: assignment, importance: 3)
      low  = create(:dossier_achievement, assignment: assignment, importance: 2)

      expect(selection.included?(high)).to be(true)
      expect(selection.included?(low)).to be(false)
      variant.min_importance = 2
      expect(described_class.new(variant, today: today).included?(low)).to be(true)
    end

    it "Includes Skills with professional years" do
      skill = create(:dossier_skill, name: "Jira")
      assignment_in(engagement, test_tools_na: false, test_tools_text: "Jira")

      expect(selection.included?(skill)).to be(true)
    end

    it "Includes Degrees, Diplomas, Certifications and Awards" do
      certification = create(:dossier_credential, :certification, user: user)

      expect(selection.included?(certification)).to be(true)
    end

    it "Lets an explicit row win over the default" do
      recent = engagement(:current)
      low = create(:dossier_achievement, assignment: assignment_in(recent), importance: 1)
      variant.items.create!(item: recent, included: false)
      variant.items.create!(item: low, included: true)

      expect(selection.included?(recent)).to be(false)
      expect(selection.included?(low)).to be(true)
      expect(selection.default?(recent)).to be(true)
    end

    it "Writes a row only where a tick differs from the default, and drops rows back at the default" do
      recent = engagement(:current)
      low = create(:dossier_achievement, assignment: assignment_in(recent), importance: 1)
      high = create(:dossier_achievement, assignment: low.assignment, importance: 5)
      variant.items.create!(item: high, included: false)

      selection.save!([ [ recent, true ], [ low, true ], [ high, true ] ])

      expect(variant.items.reload.map { |i| [ i.item, i.included ] }).to eq([ [ low, true ] ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves out Personal Projects" do
      expect(selection.included?(engagement(:personal))).to be(false)
    end

    it "Leaves out Training and expired Credentials" do
      course = create(:dossier_credential, user: user)
      expired = create(:dossier_credential, :certification, user: user, expires_month: "2021-01")

      expect(selection.included?(course)).to be(false)
      expect(selection.included?(expired)).to be(false)
    end

    it "Leaves out Uncategorised Skills and Skills only learned on Training" do
      assignment_in(engagement, test_tools_na: false, test_tools_text: "Brand New Tool")
      trained = create(:dossier_skill, name: "Scrum")
      create(:dossier_credential, user: user, skills_text: "Scrum")

      expect(selection.included?(Dossier::Skill.find_by!(name: "Brand New Tool"))).to be(false)
      expect(selection.included?(trained)).to be(false)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Condenses Engagements that ended over 10 years ago: kept, but without their Assignments" do
      old = engagement(start_month: "2010-01", end_month: "2015-12")
      assignment = assignment_in(old)

      expect(selection.included?(old)).to be(true)
      expect(selection.included?(assignment)).to be(false)
      expect(selection.condensed?(old)).to be(true)
    end

    it "Shows an old Engagement in full once one of its Assignments is ticked" do
      old = engagement(start_month: "2010-01", end_month: "2015-12")
      variant.items.create!(item: assignment_in(old), included: true)

      expect(selection.condensed?(old)).to be(false)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Counts an Engagement ending in the month exactly 10 years ago as recent" do
      edge = engagement(start_month: "2015-01", end_month: "2016-11")

      expect(selection.included?(assignment_in(edge))).to be(true)
    end

    it "Hides a ticked Achievement whose Assignment is left out" do
      old = engagement(start_month: "2010-01", end_month: "2015-12")
      achievement = create(:dossier_achievement, assignment: assignment_in(old), importance: 5)

      expect(selection.included?(achievement)).to be(true)
      expect(selection.shown?(achievement)).to be(false)
    end

    it "Rejects records it has no rule for" do
      expect { selection.included?(create(:dossier_organisation)) }.to raise_error(ArgumentError)
    end
  end
end
