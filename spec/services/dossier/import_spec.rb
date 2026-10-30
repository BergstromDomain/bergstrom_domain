# spec/services/dossier/import_spec.rb
require "rails_helper"

RSpec.describe Dossier::Import do
  let(:admin) { create(:user, :admin) }
  let(:user)  { create(:user, :content_creator) }

  let!(:consultant) { create(:dossier_employment_type, name: "Consultant") }
  let!(:permanent)  { create(:dossier_employment_type, :permanent, name: "Permanent Employment") }
  let!(:test_lead)  { create(:dossier_role, name: "Test Lead") }
  let!(:government) { create(:dossier_industry, name: "Government") }
  let!(:brisbane)   { create(:dossier_location, city: "Brisbane", country: "Australia") }

  let(:yaml) { <<~YAML }
    profile:
      name: Alex Example
      headline: Test Manager
      email: alex@example.com
      phone: "0400 000000"
      location: Brisbane, Australia
      citizenship: Australian
      linkedin_url: https://www.linkedin.com/in/alex-example/
      summaries:
        - { voice: third_person, text: "Alex tests things." }
        - { voice: first_person, text: "I test things." }
        - { voice: third_person, text: "An older third-person text." }
      terse_summary:
        text: Test manager who tests things.

    organisations:
      - { name: Acme Consulting, kind: employer }
      - { name: Department of Examples, abbreviation: DOE, kind: client, industry: Government, description: "A government department." }
      - { name: Widget Works, kind: employer, location: Sweden }

    skills:
      Test Automation: [Robot Framework, "Provar (D)"]
      Test Automation (O): [Selenium, Robot Framework]

    engagements:
      - employer: Acme Consulting
        employment_type: Consultant
        position: Test Consultant
        start: 2019-01
        end: current
        description: A test consultancy.
        assignments:
          - client: Department of Examples
            role: Test Lead
            start: 2019-03
            end: current
            summary: The verbatim original summary.
            vendors: [Secret Vendor]
            tech_stack:
              operating_systems: Windows 10, Windows 11
              methodology: Hybrid
              system_under_test: Licensing system
              test_tools: [Robot Framework, Jira]
              other_tools: N/A
              protocols: N/A
              unconfirmed: [Guessed Tool]
            terse:
              summary: Led testing of the licensing system.
              achievements: [Did a thing]
      - employer: Widget Works
        employment_type: Permanent Employment
        position: Test Engineer
        start: 2010-03-15
        end: 2018-12
        assignments:
          - client: Widget Works
            role: Test Lead
            start: 2010-03-15
            end: 2014-06
            tech_stack: { operating_systems: N/A, methodology: N/A, system_under_test: Widgets, test_tools: [Selenium], other_tools: N/A, protocols: N/A }
            terse: { summary: Tested widgets. }
          - client: Widget Works
            role: Test Lead
            start: 2014-07
            end: 2018-12
            tech_stack: { operating_systems: N/A, methodology: N/A, system_under_test: Gadgets, test_tools: N/A, other_tools: N/A, protocols: N/A }
            terse: { summary: Tested gadgets. }
  YAML

  def import(as: admin, text: yaml) = described_class.new(as, text)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Imports the Profile from the terse summary and the first summary per voice" do
      import.import!

      profile = admin.reload.dossier_profile
      expect(profile).to have_attributes(
        display_name: "Alex Example", headline: "Test Manager", email: "alex@example.com",
        phone: "0400 000000", location: brisbane, linkedin_url: "https://www.linkedin.com/in/alex-example/",
        summary: "Test manager who tests things.", summary_first_person: "I test things.",
        summary_third_person: "Alex tests things.", classification: "restricted"
      )
    end

    it "Imports Organisations with their abbreviation, Industry and description" do
      import.import!

      doe = Dossier::Organisation.find_by!(name: "Department of Examples")
      expect(doe).to have_attributes(abbreviation: "DOE", industry: government, description: "A government department.")
      expect(Dossier::Organisation.pluck(:name)).to include("Acme Consulting", "Widget Works")
    end

    it "Imports Skills into their category, without source tags" do
      import.import!

      automation = Dossier::SkillCategory.find_by!(name: "Test Automation")
      expect(automation.skills.pluck(:name)).to contain_exactly("Robot Framework", "Provar", "Selenium")
      expect(Dossier::SkillCategory.where("name LIKE ?", "%(O)%")).to be_empty
    end

    it "Imports Engagements and Assignments as restricted, with the terse summary and Tech Stack" do
      import.import!

      engagement = admin.dossier_engagements.find_by!(position_title: "Test Consultant")
      expect(engagement).to have_attributes(employment_type: consultant, start_on: Date.new(2019, 1, 1),
                                            start_precision: "month", end_on: nil,
                                            summary: "A test consultancy.", classification: "restricted")

      assignment = engagement.assignments.sole
      expect(assignment).to have_attributes(role: test_lead, start_on: Date.new(2019, 3, 1), end_on: nil,
                                            summary: "Led testing of the licensing system.",
                                            system_under_test: "Licensing system", classification: "restricted",
                                            other_tools_na: true, protocols_na: true)
      expect(assignment.client.name).to eq("Department of Examples")
      expect(assignment.operating_systems_text).to eq("Windows 10, Windows 11")
      expect(assignment.methodologies_text).to eq("Hybrid")
      expect(assignment.test_tools_text).to eq("Robot Framework, Jira")
    end

    it "Reports what it created" do
      result = import.import!

      expect(result).to be_ok
      expect(result.created).to include(
        "Profile" => [ "Alex Example" ],
        "Engagement" => [ "Test Consultant at Acme Consulting", "Test Engineer at Widget Works" ]
      )
      expect(result.created["Organisation"]).to include("Department of Examples")
      expect(result.created["Assignment"].size).to eq(3)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Changes nothing in a preview" do
      result = import.preview

      expect(result).to be_ok
      expect(result.created["Engagement"].size).to eq(2)
      expect(Dossier::Engagement.count).to eq(0)
      expect(Dossier::Organisation.count).to eq(0)
      expect(admin.reload.dossier_profile).to be_nil
    end

    it "Rejects a file that isn't YAML" do
      result = import(text: "profile: [unclosed").preview

      expect(result).not_to be_ok
      expect(result.errors.first).to start_with("Not a valid YAML file")
    end

    it "Rejects YAML that isn't a master list" do
      expect(import(text: "- just\n- a list\n").preview.errors).to eq([ "Not a master list: expected profile, organisations, skills or engagements" ])
    end

    it "Imports nothing when any record is invalid" do
      broken = yaml.sub("start: 2019-03\n", "start: 2018-03\n") # before its Engagement starts

      result = import(text: broken).import!

      expect(result).not_to be_ok
      expect(result.errors.first).to include("Assignment Test Lead at Department of Examples", "must not be before the Engagement starts")
      expect(Dossier::Engagement.count).to eq(0)
    end

    it "Stops a non-admin from creating an unknown Employment Type" do
      unknown = yaml.sub("employment_type: Consultant", "employment_type: Freelancer")

      result = import(as: user, text: unknown).preview

      expect(result.errors).to include("Engagement Test Consultant at Acme Consulting: unknown Employment Type 'Freelancer' — ask an Admin to add it")
    end

    it "Ignores the private fields" do
      import.import!

      expect(Dossier::Skill.find_by(name: "Guessed Tool")).to be_nil
      expect(Dossier::Organisation.find_by(name: "Secret Vendor")).to be_nil
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Skips records that already exist and lists them" do
      import.import!

      result = import.import!

      expect(result).to be_ok
      expect(result.created).to be_empty
      expect(result.existing["Engagement"]).to eq([ "Test Consultant at Acme Consulting", "Test Engineer at Widget Works" ])
      expect(result.existing["Profile"]).to eq([ "Alex Example" ])
      expect(Dossier::Assignment.count).to eq(3)
    end

    it "Keeps edits made in the app on a re-import" do
      import.import!
      Dossier::Organisation.find_by!(name: "Department of Examples").update!(description: "Edited.")

      import.import!

      expect(Dossier::Organisation.find_by!(name: "Department of Examples").description).to eq("Edited.")
    end

    it "Gives a permanent Engagement's own Assignment the first listed details" do
      import.import!

      engagement = admin.dossier_engagements.find_by!(position_title: "Test Engineer")
      expect(engagement.start_on).to eq(Date.new(2010, 3, 15))
      expect(engagement.start_precision).to eq("day")
      expect(engagement.assignments.order(:start_on).map(&:summary)).to eq([ "Tested widgets.", "Tested gadgets." ])
      expect(engagement.assignments.order(:start_on).first.end_on).to eq(Date.new(2014, 6, 1))
    end

    it "Lets an Admin create missing reference data" do
      text = yaml.sub("role: Test Lead", "role: Acting Test Manager").sub("employment_type: Consultant", "employment_type: Freelancer")

      result = import(text: text).import!

      expect(result).to be_ok
      expect(Dossier::Role.find_by(name: "Acting Test Manager")).to be_present
      expect(Dossier::EmploymentType.find_by(name: "Freelancer")).to have_attributes(permanent: false)
      expect(result.created["Role"]).to eq([ "Acting Test Manager" ])
    end

    it "Leaves optional reference data empty for a non-admin, with a warning" do
      text = yaml.sub("role: Test Lead", "role: Acting Test Manager").sub("industry: Government", "industry: Mining")

      result = import(as: user, text: text).import!

      expect(result).to be_ok
      expect(Dossier::Role.find_by(name: "Acting Test Manager")).to be_nil
      expect(user.dossier_engagements.find_by!(position_title: "Test Consultant").assignments.sole.role).to be_nil
      expect(result.warnings).to include(
        "Assignment Test Consultant at Department of Examples: unknown Role 'Acting Test Manager' left empty",
        "Organisation Department of Examples: unknown Industry 'Mining' left empty"
      )
    end

    it "Puts a non-admin's Skills of an unknown category in Uncategorised" do
      result = import(as: user).import!

      expect(Dossier::Skill.find_by!(name: "Provar").skill_category.name).to eq("Uncategorised")
      expect(result.warnings).to include("Skill Category 'Test Automation' is unknown — its Skills go in Uncategorised")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Matches an existing Skill by alias instead of creating it" do
      jenkins = create(:dossier_skill, name: "Jenkins", aliases: [ "Robot Framework" ])

      import.import!

      expect(Dossier::Skill.where(name: "Robot Framework")).to be_empty
      expect(admin.dossier_engagements.find_by!(position_title: "Test Consultant").assignments.sole.skills).to include(jenkins)
    end

    it "Keeps two Assignments for the same client and start month when their Roles differ" do
      second = <<~YAML.indent(6)
        - client: Department of Examples
          role: Test Manager
          start: 2019-03
          end: 2019-09
          tech_stack: { operating_systems: N/A, methodology: N/A, system_under_test: Pilot, test_tools: N/A, other_tools: N/A, protocols: N/A }
      YAML
      text = yaml.sub("  - employer: Widget Works", "#{second}  - employer: Widget Works")

      import(text: text).import!

      engagement = admin.dossier_engagements.find_by!(position_title: "Test Consultant")
      expect(engagement.assignments.map(&:role_name)).to contain_exactly("Test Lead", "Test Manager")
    end

    it "Imports a file with only some sections" do
      result = import(text: "organisations:\n  - { name: Solo Org }\n").import!

      expect(result).to be_ok
      expect(result.created).to eq("Organisation" => [ "Solo Org" ])
    end

    it "Reads an exact date as day precision and current as no end" do
      import.import!

      widget = admin.dossier_engagements.find_by!(position_title: "Test Engineer")
      expect([ widget.start_precision, widget.end_precision ]).to eq(%w[day month])
      expect(admin.dossier_engagements.find_by!(position_title: "Test Consultant")).to be_current
    end
  end
end
