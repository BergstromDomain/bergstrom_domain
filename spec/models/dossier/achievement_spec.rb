# spec/models/dossier/achievement_spec.rb
require "rails_helper"

RSpec.describe Dossier::Achievement, type: :model do
  let(:assignment) { create(:dossier_assignment) }
  let!(:test_tools) { create(:dossier_skill_category, name: "Test Tools") }
  let!(:jira) { create(:dossier_skill, name: "Jira", aliases: [ "Atlassian Jira" ], skill_category: test_tools) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:assignment_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:text).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:impact).of_type(:string) }
    it { is_expected.to have_db_column(:importance).of_type(:integer).with_options(null: false, default: 3) }
    it { is_expected.to have_db_column(:position).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:classification).of_type(:string).with_options(null: false, default: "restricted") }
    it { is_expected.to have_db_column(:deleted_at).of_type(:datetime) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to have_many(:skills).through(:achievement_skills) }

    it "Keeps a Skill from being deleted while an Achievement is tagged with it" do
      create(:dossier_achievement, assignment: assignment, skills_text: "Jira")
      expect(jira.destroy).to be false
    end
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is valid with text, owned by the Assignment's user, Private, importance 3" do
      achievement = create(:dossier_achievement, assignment: assignment)
      expect(achievement.user).to eq(assignment.user)
      expect(achievement).to be_restricted
      expect(achievement.importance).to eq(3)
    end

    it "Goes to the end of its Assignment's list" do
      first = create(:dossier_achievement, assignment: assignment)
      second = create(:dossier_achievement, assignment: assignment)
      expect(assignment.reload.achievements).to eq([ first, second ])
      expect(second.position).to eq(first.position + 1)
    end

    it "Tags Skills from comma-separated text, by name or alias" do
      achievement = create(:dossier_achievement, assignment: assignment, skills_text: "atlassian jira, Excel")
      expect(achievement.skills.map(&:name)).to eq(%w[Jira Excel])
      expect(achievement.skills.last.skill_category.name).to eq("Uncategorised")
      expect(achievement.skills_text).to eq("Jira, Excel")
    end

    it "Moves up and down past its neighbours" do
      first, second, third = Array.new(3) { create(:dossier_achievement, assignment: assignment) }
      expect(third.move!(:up)).to be true
      expect(assignment.reload.achievements).to eq([ first, third, second ])
      expect(first.reload.move!(:down)).to be true
      expect(assignment.reload.achievements).to eq([ third, first, second ])
    end

    it "Is labelled with its first 60 or so characters" do
      achievement = build(:dossier_achievement, text: "Coordinated user acceptance testing with the business for each monthly release")
      expect(achievement.to_toast_label).to eq("Coordinated user acceptance testing with the business for...")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid without text" do
      achievement = build(:dossier_achievement, text: "  ")
      expect(achievement).not_to be_valid
      expect(achievement.errors[:text]).to include("can't be blank")
    end

    it "Is invalid with an importance outside 1–5" do
      [ 0, 6 ].each do |importance|
        expect(build(:dossier_achievement, importance: importance)).not_to be_valid
      end
    end

    it "Doesn't move past either end" do
      first, last = Array.new(2) { create(:dossier_achievement, assignment: assignment) }
      expect(first.move!(:up)).to be false
      expect(last.move!(:down)).to be false
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Soft-deletes: hidden from its Assignment's list, restorable in place" do
      first, second = Array.new(2) { create(:dossier_achievement, assignment: assignment) }
      first.soft_delete!
      expect(assignment.reload.achievements).to eq([ second ])
      expect(first.purge_at).to be_within(1.second).of(first.deleted_at + 30.days)

      first.restore!
      expect(assignment.reload.achievements).to eq([ first, second ])
    end

    it "Untags Skills removed from the text" do
      achievement = create(:dossier_achievement, assignment: assignment, skills_text: "Jira, Excel")
      achievement.update!(skills_text: "Excel")
      expect(achievement.reload.skills.map(&:name)).to eq(%w[Excel])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Skips deleted neighbours when moving" do
      first, middle, last = Array.new(3) { create(:dossier_achievement, assignment: assignment) }
      middle.soft_delete!
      last.move!(:up)
      expect(assignment.reload.achievements).to eq([ last, first ])
    end

    it "Goes with its Assignment, deleted ones included" do
      create(:dossier_achievement, assignment: assignment)
      create(:dossier_achievement, assignment: assignment).soft_delete!
      expect { assignment.destroy }.to change(described_class, :count).by(-2)
    end

    it "Tags a Skill once, however often it's typed" do
      achievement = create(:dossier_achievement, assignment: assignment, skills_text: "Jira, jira, Atlassian Jira")
      expect(achievement.skills.map(&:name)).to eq(%w[Jira])
    end
  end
end
