# spec/models/dossier/tech_stack_categories_spec.rb
require "rails_helper"

# The Assignment form's Tech Stack: a field per top-level Skill Category (in
# position order) plus Other Skills. Each Skill is still stored in one of the
# six lists, chosen by its category; lists left empty become N/A.
RSpec.describe "Dossier Assignment Tech Stack by Skill Category", type: :model do
  let!(:uncategorised) { create(:dossier_skill_category, name: "Uncategorised") }
  let!(:testing)       { create(:dossier_skill_category, name: "Testing", position: 1) }
  let!(:management)    { create(:dossier_skill_category, name: "Test & Issue Management", parent: testing, position: 1) }
  let!(:databases)     { create(:dossier_skill_category, name: "Databases", position: 2) }
  let!(:methods)       { create(:dossier_skill_category, name: "Methods & Processes", position: 3) }
  let!(:systems)       { create(:dossier_skill_category, name: "Operating Systems", position: 4) }
  let!(:protocols)     { create(:dossier_skill_category, name: "Protocols & Standards", position: 5) }
  let(:engagement)     { create(:dossier_engagement) }

  def assignment(**attributes)
    create(:dossier_assignment, engagement: engagement, systems_under_test_na: false,
                                systems_under_test_text: "Ticketing", **attributes)
  end

  def fields(**texts) = texts.to_h { |key, text| [ key == :other ? "other" : send(key).id.to_s, text ] }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Lists the top-level categories with a position, in order" do
      create(:dossier_skill_category, name: "System Under Test")

      expect(Dossier::TechStack.form_categories).to eq([ testing, databases, methods, systems, protocols ])
    end

    it "Saves each field's Skills in the list their category belongs to, and marks the empty lists N/A" do
      jira = create(:dossier_skill, name: "Jira", skill_category: management)
      oracle = create(:dossier_skill, name: "Oracle", skill_category: databases)
      record = assignment
      record.update!(category_skills_text: fields(testing: "Jira", databases: "Oracle", methods: "Scrum",
                                                  systems: "", protocols: "", other: ""))

      expect(record.skills_in(:test_tool)).to eq([ jira ])
      expect(record.skills_in(:other_tool)).to eq([ oracle ])
      expect(record.skills_in(:methodology).map(&:name)).to eq([ "Scrum" ])
      expect(record).to have_attributes(test_tools_na: false, other_tools_na: false, methodologies_na: false,
                                        operating_systems_na: true, protocols_na: true)
    end

    it "Creates unknown names in the field's category, and Other Skills' in Uncategorised" do
      record = assignment
      record.update!(category_skills_text: fields(databases: "Snowflake", other: "Gizmo"))

      expect(Dossier::Skill.find_by(name: "Snowflake").skill_category).to eq(databases)
      expect(Dossier::Skill.find_by(name: "Gizmo").skill_category).to eq(uncategorised)
      expect(record.skills_in(:other_tool).map(&:name)).to contain_exactly("Snowflake", "Gizmo")
    end

    it "Shows each field's Skills, sub-categories included, versions with their parent, the rest under Other Skills" do
      windows = create(:dossier_skill, name: "Windows", skill_category: systems)
      %w[XP 7].each { |label| create(:dossier_skill, name: label, skill_category: systems, parent: windows) }
      create(:dossier_skill, name: "Jira", skill_category: management)
      create(:dossier_skill, name: "Gizmo", skill_category: uncategorised)
      record = assignment(test_tools_na: false, test_tools_text: "Jira, Gizmo",
                          operating_systems_na: false, operating_systems_text: "Linux, Windows (XP, 7)")

      expect(record.category_skills_text(testing.id)).to eq("Jira")
      expect(record.category_skills_text(systems.id)).to eq("Windows (XP, 7)")
      expect(record.category_skills_text("other")).to eq("Gizmo, Linux")
      expect(record.category_skills_text(databases.id)).to eq("")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is still invalid without a System Under Test or N/A" do
      record = assignment
      record.assign_attributes(systems_under_test_text: "", category_skills_text: fields(testing: "Jira"))

      expect(record).not_to be_valid
      expect(record.errors[:systems_under_test_text]).to include("needs at least one item, or tick N/A")
    end

    it "Drops Skills taken out of a field, leaving the System Under Test alone" do
      create(:dossier_skill, name: "Jira", skill_category: management)
      record = assignment(test_tools_na: false, test_tools_text: "Jira")
      record.update!(category_skills_text: fields(testing: ""))

      expect(record.reload.skills_in(:test_tool)).to be_empty
      expect(record.test_tools_na).to be(true)
      expect(record.skills_in(:system_under_test).map(&:name)).to eq([ "Ticketing" ])
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Keeps a Skill already on the Assignment in its list" do
      excel = create(:dossier_skill, name: "Excel", skill_category: databases)
      record = assignment(test_tools_na: false, test_tools_text: "Excel")
      record.update!(category_skills_text: fields(databases: "Excel"))

      expect(record.reload.skills_in(:test_tool)).to eq([ excel ])
    end

    it "Files an existing Skill typed into another field by its own category" do
      jira = create(:dossier_skill, name: "Jira", skill_category: management)
      record = assignment
      record.update!(category_skills_text: fields(databases: "Jira"))

      expect(jira.reload.skill_category).to eq(management)
      expect(record.skills_in(:test_tool)).to eq([ jira ])
      expect(record.category_skills_text(testing.id)).to eq("Jira")
    end

    it "Puts Methods, Operating Systems and Protocols in their own lists" do
      record = assignment
      record.update!(category_skills_text: fields(methods: "Scrum", systems: "Linux", protocols: "HL7"))

      expect(%i[methodology operating_system protocol].map { |slot| record.skills_in(slot).map(&:name) })
        .to eq([ [ "Scrum" ], [ "Linux" ], [ "HL7" ] ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Keeps a Skill on both the System Under Test and a category field" do
      create(:dossier_skill, name: "Ticketing", skill_category: databases)
      record = assignment
      record.update!(category_skills_text: fields(databases: "Ticketing"))

      expect(record.reload.skills_in(:system_under_test).map(&:name)).to eq([ "Ticketing" ])
      expect(record.skills_in(:other_tool).map(&:name)).to eq([ "Ticketing" ])
    end

    it "Changes nothing when the category fields aren't sent (the six lists still work alone)" do
      create(:dossier_skill, name: "Jira", skill_category: management)
      record = assignment(test_tools_na: false, test_tools_text: "Jira")
      record.update!(project: "Upgrade")

      expect(record.reload.skills_in(:test_tool).map(&:name)).to eq([ "Jira" ])
      expect(record.test_tools_na).to be(false)
    end

    it "Adds a new version in the field's category, filed under its parent's list" do
      windows = create(:dossier_skill, name: "Windows", skill_category: systems)
      record = assignment
      record.update!(category_skills_text: fields(systems: "Windows (12)"))

      version = Dossier::Skill.find_by(name: "Windows 12")
      expect(version).to have_attributes(parent: windows, skill_category: systems)
      expect(record.skills_in(:operating_system)).to eq([ version ])
    end
  end
end
