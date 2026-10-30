# spec/models/dossier/tech_stack_spec.rb
require "rails_helper"

# Dossier::TechStack on Dossier::Assignment: System Under Test plus five Skill
# lists, each filled or marked N/A (never both, never neither).
RSpec.describe "Dossier Assignment Tech Stack", type: :model do
  let!(:uncategorised) { create(:dossier_skill_category, name: "Uncategorised") }
  let(:tools)          { create(:dossier_skill_category, name: "Test Tools") }
  let(:engagement)     { create(:dossier_engagement) }

  def assignment(**attributes)
    build(:dossier_assignment, engagement: engagement, system_under_test: "Salesforce CRM", **attributes)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Saves each list's Skills in their slot, reusing existing Skills by name or alias" do
      jira = create(:dossier_skill, name: "Jira", skill_category: tools)
      selenium = create(:dossier_skill, name: "Selenium", aliases_text: "WebDriver", skill_category: tools)

      record = assignment(test_tools_na: false, test_tools_text: "jira, webdriver",
                          methodologies_na: false, methodologies_text: "Hybrid")
      record.save!

      expect(record.skills_in(:test_tool)).to contain_exactly(jira, selenium)
      expect(record.skills_in(:methodology).map(&:name)).to eq([ "Hybrid" ])
      expect(record.reload.test_tools_text).to eq("Jira, Selenium")
    end

    it "Creates unknown Skills in the Uncategorised Skill Category" do
      record = assignment(protocols_na: false, protocols_text: "HL7")
      record.save!
      expect(Dossier::Skill.find_by!(name: "HL7").skill_category).to eq(uncategorised)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid without a System Under Test" do
      record = assignment(system_under_test: " ")
      expect(record).not_to be_valid
      expect(record.errors[:system_under_test]).to include("can't be blank")
    end

    it "Is invalid with a list that is neither filled nor N/A" do
      record = assignment(test_tools_na: false, test_tools_text: "")
      expect(record).not_to be_valid
      expect(record.errors[:test_tools_text]).to include("needs at least one item, or tick N/A")
    end

    it "Is invalid with a list that is both filled and N/A" do
      record = assignment(test_tools_na: true, test_tools_text: "Jira")
      expect(record).not_to be_valid
      expect(record.errors[:test_tools_text]).to include("must be empty when N/A is ticked")
    end

    it "Keeps a Skill from being deleted while a Tech Stack uses it" do
      record = assignment(test_tools_na: false, test_tools_text: "Jira")
      record.save!
      expect(Dossier::Skill.find_by!(name: "Jira").destroy).to be(false)
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Replaces a list's Skills on update, leaving other slots alone" do
      record = assignment(test_tools_na: false, test_tools_text: "Jira, qTest",
                          other_tools_na: false, other_tools_text: "Excel")
      record.save!
      record.update!(test_tools_text: "Tosca")

      expect(record.reload.test_tools_text).to eq("Tosca")
      expect(record.other_tools_text).to eq("Excel")
    end

    it "Lets the same Skill sit in two slots (Excel as a test tool and another tool)" do
      record = assignment(test_tools_na: false, test_tools_text: "Excel", other_tools_na: false, other_tools_text: "Excel")
      record.save!
      expect(Dossier::Skill.where(name: "Excel").count).to eq(1)
      expect(record.assignment_skills.count).to eq(2)
    end

    it "Gives a permanent job's automatic Assignment an all-N/A Tech Stack" do
      engagement = create(:dossier_engagement, :permanent)
      record = engagement.assignments.first
      expect(record.system_under_test).to eq("N/A")
      expect(record).to be_tech_stack_blank
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Ignores blanks and repeats in a list" do
      record = assignment(test_tools_na: false, test_tools_text: " Jira, , JIRA ,Jira")
      record.save!
      expect(record.reload.test_tools_text).to eq("Jira")
    end

    it "Is tech-stack-blank only when every list is N/A and the System Under Test is N/A" do
      expect(assignment(system_under_test: "N/A")).to be_tech_stack_blank
      expect(assignment(system_under_test: "Salesforce CRM")).not_to be_tech_stack_blank
    end
  end
end
