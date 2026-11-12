# spec/services/dossier/tech_stack_coverage_spec.rb

require "rails_helper"

# Keeps an Assignment's Tech Stack and its Achievements in step: an
# Achievement's Tech Skills go in the Stack (add!), and the Stack Skills no
# Achievement names are listed (uncovered) so the Assignment page can warn.
RSpec.describe Dossier::TechStackCoverage do
  let(:charlie)    { create(:user, :content_creator) }
  let(:engagement) { create(:dossier_engagement, user: charlie) }
  let(:assignment) { create(:dossier_assignment, engagement: engagement) }

  def category(name, **attributes)
    Dossier::SkillCategory.find_by(name: name) || create(:dossier_skill_category, name: name, **attributes)
  end

  def skill(name, in_category, parent: nil)
    Dossier::Skill.find_by(name: name) || create(:dossier_skill, name: name, skill_category: category(in_category), parent: parent)
  end

  let!(:test_strategy) { skill("Test Strategy", "Methods & Processes") }
  let!(:azure_devops)  { skill("Azure DevOps", "Testing") }
  let!(:provar)        { skill("Provar", "Testing") }
  let!(:salesforce)    { skill("Salesforce", "Business Applications") }
  let!(:teams)         { skill("Teams", "Office & Collaboration") }
  let!(:windows)       { skill("Windows", "Operating Systems") }
  let!(:leadership)    { create(:dossier_skill, name: "Leadership", skill_category: category("Soft Skills", soft: true)) }

  def stack(**texts)
    assignment.update!(texts.to_h { |plural, text| [ :"#{plural}_text", text ] }
                            .merge(texts.keys.to_h { |plural| [ :"#{plural}_na", false ] }))
    assignment.reload
  end

  def achievement(skills_text, **attributes)
    create(:dossier_achievement, assignment: assignment, skills_text: skills_text, **attributes)
  end

  def stack_names(slot) = assignment.reload.skills_in(slot).map(&:name)

  def coverage = described_class.new(assignment.reload)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds an Achievement's Tech Skill to the list for its category, clearing that list's N/A" do
      added = coverage.add!(achievement("Test Strategy").technical_skills)

      expect(added).to eq([ test_strategy ])
      expect(stack_names(:methodology)).to eq([ "Test Strategy" ])
      expect(assignment.methodologies_na).to be(false)
      expect(assignment).to be_valid
    end

    it "Lists the Stack Skills no Achievement names" do
      stack(test_tools: "Azure DevOps, Provar")
      achievement("Provar")

      expect(coverage.uncovered).to eq([ azure_devops ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Never adds a Soft Skill to the Stack" do
      added = coverage.add!(achievement("", soft_skill_ids: [ leadership.id ]).current_skills)

      expect(added).to eq([])
      expect(assignment.reload.skills).to be_empty
    end

    it "Lists nothing when every Stack Skill is named" do
      stack(test_tools: "Provar", methodologies: "Test Strategy")
      achievement("Provar, Test Strategy")

      expect(coverage.uncovered).to eq([])
    end

    it "Doesn't count a deleted Achievement's Skills" do
      stack(test_tools: "Provar")
      achievement("Provar").soft_delete!

      expect(coverage.uncovered).to eq([ provar ])
    end

    it "Adds nothing on a dry run" do
      expect(coverage.add!([ test_strategy ], dry_run: true)).to eq([ test_strategy ])
      expect(assignment.reload.skills).to be_empty
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Doesn't ask for System Under Test Skills, even when they're in another list too" do
      stack(systems_under_test: "Salesforce", other_tools: "Salesforce")

      expect(coverage.uncovered).to eq([])
    end

    it "Doesn't ask for Office & Collaboration or Operating Systems Skills" do
      stack(other_tools: "Teams", operating_systems: "Windows")

      expect(coverage.uncovered).to eq([])
    end

    it "Counts a Skill's versions as the Skill, both ways" do
      windows_10 = skill("10", "Operating Systems", parent: windows)
      azure_2020 = skill("2020", "Testing", parent: azure_devops)
      stack(test_tools: "Azure DevOps (2020)")
      achievement("Azure DevOps")

      expect(coverage.uncovered).to eq([])

      stack(operating_systems: "Windows")
      expect(coverage.add!([ windows_10 ])).to eq([])
      expect(azure_2020.family_root).to eq(azure_devops)
    end

    it "Leaves a Skill already in System Under Test where it is" do
      stack(systems_under_test: "Salesforce")

      expect(coverage.add!([ salesforce ])).to eq([])
      expect(stack_names(:other_tool)).to eq([])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Puts a new, Uncategorised Skill in Other Tools" do
      added = coverage.add!(achievement("Statistics").technical_skills)

      expect(added.map(&:name)).to eq([ "Statistics" ])
      expect(stack_names(:other_tool)).to eq([ "Statistics" ])
    end

    it "Lists uncovered Skills in Stack order, each once" do
      stack(methodologies: "Test Strategy", test_tools: "Azure DevOps, Provar")

      expect(coverage.uncovered).to eq([ test_strategy, azure_devops, provar ])
    end

    it "Lists nothing for an all N/A Stack" do
      achievement("Provar")

      expect(coverage.uncovered).to eq([])
    end

    it "Backfills every kept Achievement's Tech Skills into its Assignment's Stack, reporting each Assignment once" do
      achievement("Test Strategy")
      achievement("Provar, Test Strategy")
      achievement("Azure DevOps").soft_delete!
      other = create(:dossier_assignment, engagement: create(:dossier_engagement, user: create(:user, :content_creator)))
      create(:dossier_achievement, assignment: other, skills_text: "Provar")

      expect(described_class.backfill(charlie, dry_run: true)).to eq([ "#{assignment.heading}: Test Strategy, Provar" ])
      expect(assignment.reload.skills).to be_empty

      expect(described_class.backfill(charlie)).to eq([ "#{assignment.heading}: Test Strategy, Provar" ])
      expect(assignment.reload.skills).to contain_exactly(test_strategy, provar)
      expect(other.reload.skills).to be_empty
      expect(described_class.backfill(charlie)).to eq([])
    end

    it "Adds a Skill the Achievement names twice, once" do
      expect(coverage.add!([ provar, provar ])).to eq([ provar ])
      expect(stack_names(:test_tool)).to eq([ "Provar" ])
    end
  end
end
