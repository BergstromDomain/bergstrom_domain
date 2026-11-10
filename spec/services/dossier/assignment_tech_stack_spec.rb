# spec/services/dossier/assignment_tech_stack_spec.rb
require "rails_helper"

RSpec.describe Dossier::AssignmentTechStack do
  let(:testing)    { create(:dossier_skill_category, name: "Testing", position: 1) }
  let(:automation) { create(:dossier_skill_category, name: "Test Automation", parent: testing, position: 1) }
  let(:management) { create(:dossier_skill_category, name: "Test & Issue Management", parent: testing, position: 2) }
  let(:documents)  { create(:dossier_skill_category, name: "Test Documentation", parent: testing, position: 3) }
  let(:systems)    { create(:dossier_skill_category, name: "Operating Systems", position: 2) }
  let(:sut)        { create(:dossier_skill_category, name: "System Under Test") }

  def skill(name, category, **attributes) = create(:dossier_skill, name: name, skill_category: category, **attributes)

  def assignment_with(**lists)
    attributes = lists.to_h { |plural, names| [ :"#{plural}_text", names ] }
                      .merge(lists.keys.to_h { |plural| [ :"#{plural}_na", false ] })
    create(:dossier_assignment, **attributes)
  end

  # [heading, [family labels]] per column, e.g. ["Testing", ["Jira"]]
  def layout(stack)
    stack.blocks.map do |block|
      [ block.category.name, block.columns.map { |column| [ column.heading, column.families.map { |f| label(f) } ] } ]
    end
  end

  def label(family)
    versions = family.versions.map(&:version_label)
    versions.empty? ? family.root.display_name : "#{family.root.display_name} (#{versions.join(', ')})"
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Groups Skills into a block per top-level category, its own Skills first, then a column per sub-category in order" do
      skill("Testing Strategy", testing)
      skill("Selenium", automation)
      skill("Jira", management)
      skill("Qtest", management)
      skill("Windows", systems)
      assignment = assignment_with(test_tools: "Selenium, Jira, Qtest, Testing Strategy", operating_systems: "Windows")

      expect(layout(described_class.new(assignment))).to eq([
        [ "Testing", [ [ "Testing", [ "Testing Strategy" ] ], [ "Test Automation", [ "Selenium" ] ],
                       [ "Test & Issue Management", [ "Jira", "Qtest" ] ] ] ],
        [ "Operating Systems", [ [ "Operating Systems", [ "Windows" ] ] ] ]
      ])
    end

    it "Lists the System Under Test separately, leaving it out of the blocks" do
      skill("Energy Components", sut)
      skill("SSRS", sut)
      skill("Jira", management)
      assignment = assignment_with(systems_under_test: "Energy Components, SSRS", test_tools: "Jira")
      stack = described_class.new(assignment)

      expect(stack.systems_under_test.map { |family| label(family) }).to eq([ "Energy Components", "SSRS" ])
      expect(layout(stack).map(&:first)).to eq([ "Testing" ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Has no blocks and no System Under Test when every list is N/A" do
      stack = described_class.new(create(:dossier_assignment))

      expect(stack.blocks).to be_empty
      expect(stack.systems_under_test).to be_empty
    end

    it "Leaves out sub-categories with no Skills" do
      documents
      skill("Jira", management)

      expect(layout(described_class.new(assignment_with(test_tools: "Jira"))))
        .to eq([ [ "Testing", [ [ "Testing", [] ], [ "Test & Issue Management", [ "Jira" ] ] ] ] ])
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Puts categories with no position last, A–Z, after the numbered ones" do
      skill("Jira", management)
      skill("Windows", systems)
      skill("Gizmo", create(:dossier_skill_category, name: "Uncategorised"))
      skill("TPS Reports", create(:dossier_skill_category, name: "Business Applications"))
      assignment = assignment_with(test_tools: "Gizmo, TPS Reports, Jira", operating_systems: "Windows")

      expect(layout(described_class.new(assignment)).map(&:first))
        .to eq([ "Testing", "Operating Systems", "Business Applications", "Uncategorised" ])
    end

    it "Keeps the System Under Test in the order entered, the main system first" do
      skill("SSRS", sut)
      skill("Energy Components", sut)
      skill("Historian", sut)
      stack = described_class.new(assignment_with(systems_under_test: "Energy Components, SSRS, Historian"))

      expect(stack.systems_under_test.map { |family| label(family) }).to eq([ "Energy Components", "SSRS", "Historian" ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows versions with their parent, as one family filed under the parent's category" do
      windows = skill("Windows", systems)
      skill("XP", create(:dossier_skill_category, name: "Legacy"), parent: windows)
      skill("7", systems, parent: windows)
      skill("Linux", systems)
      assignment = assignment_with(operating_systems: "Windows (XP, 7), Linux")

      expect(layout(described_class.new(assignment)))
        .to eq([ [ "Operating Systems", [ [ "Operating Systems", [ "Linux", "Windows (7, XP)" ] ] ] ] ])
    end

    it "Shows a Skill on several lists once" do
      skill("Jira", management)
      assignment = assignment_with(test_tools: "Jira", other_tools: "Jira")

      expect(layout(described_class.new(assignment)))
        .to eq([ [ "Testing", [ [ "Testing", [] ], [ "Test & Issue Management", [ "Jira" ] ] ] ] ])
    end

    it "Shows the vendor's name where the Skill asks for it" do
      microsoft = create(:dossier_organisation, name: "Microsoft")
      skill("Test Manager", management, vendor: microsoft, show_vendor_in_name: true)

      expect(layout(described_class.new(assignment_with(test_tools: "Test Manager"))).dig(0, 1, 1, 1))
        .to eq([ "Microsoft Test Manager" ])
    end
  end
end
