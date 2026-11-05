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
            project: Licensing Upgrade
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
              achievements:
                - Did a thing
                - "  Did another thing  "
                - ""
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

  let!(:degree_type) { create(:dossier_credential_type, name: "Degree", position: 1) }
  let!(:certification_type) { create(:dossier_credential_type, name: "Certification", position: 3) }
  let!(:course_type) { create(:dossier_credential_type, :training, name: "Course", position: 4) }

  # Only types that exist, so a non-admin's import isn't stopped by Workshop.
  let(:known_credentials_yaml) { credentials_yaml.sub("type: Workshop", "type: Course") }

  let(:credentials_yaml) { <<~YAML }
    credentials:
      education:
        - { title: Master of Science degree in Engineering Physics, issuer: "KTH, Royal Institute of Technology", location: "Stockholm, Sweden", year: 2001, studies_completed: 2000, note: "private" }
        - { title: "Master Thesis: Algorithms for decoding Multichannel Television Sound", issuer: "KTH, Royal Institute of Technology", supervised_at: San Diego State University, year: 2000, approved: 2001 }
        - { title: Exchange semester, issuer: San Diego State University, year: 1999 }
      education_linkedin:
        - { school: "Blackebergs gymnasium", start: 1990, end: 1992, degree: "High school" }
      certifications:
        - { title: ISTQB Foundation Certificate in Software Testing, issuer: Swedish Software Testing Board, date: 2009-08, licence: SSTBFCE-176004 }
        - { title: Certified ScrumMaster, issuer: Scrum Alliance, date: 2010-02, years: [2010, 2017] }
      training:
        - { title: Getting Started with DevOps, issuer: LinkedIn Learning, year: 2022, completed: 2022-11-15 }
        - { title: LabVIEW Basic I, issuer: National Instruments, year: 2002 }
        - { title: Presentation Technique, issuer: "?", year: "?" }
        - { title: "Anthropic Academy courses", issuer: Anthropic, status: in progress, due: 2026-11 }
        - { title: Agile Testing Workshop, issuer: "?", year: 2010, type: Workshop }
    linkedin_learning:
      completed:
        - { title: "Scrum: The Basics", type: course, completed: 2018-09-10 }
  YAML

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
                                            systems_under_test_text: "Licensing system", classification: "restricted",
                                            other_tools_na: true, protocols_na: true)
      expect(assignment.client.name).to eq("Department of Examples")
      expect(assignment.project).to eq("Licensing Upgrade")
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
      expect(result.created["Achievement"]).to eq([ "Did a thing", "Did another thing" ])
    end

    it "Imports education, certifications and training as restricted Credentials of their type" do
      result = import(as: user, text: known_credentials_yaml).import!

      expect(result).to be_ok
      msc = user.dossier_credentials.find_by!(title: "Master of Science degree in Engineering Physics")
      expect(msc).to have_attributes(credential_type: degree_type, start_on: Date.new(2001, 1, 1), start_precision: "year",
                                     end_on: Date.new(2001, 1, 1), end_precision: "year", classification: "restricted")
      expect(msc.provider.name).to eq("KTH, Royal Institute of Technology")
      istqb = user.dossier_credentials.find_by!(title: "ISTQB Foundation Certificate in Software Testing")
      expect(istqb).to have_attributes(credential_type: certification_type, end_on: Date.new(2009, 8, 1),
                                       end_precision: "month", certificate_number: "SSTBFCE-176004")
      devops = user.dossier_credentials.find_by!(title: "Getting Started with DevOps")
      expect(devops).to have_attributes(credential_type: course_type, end_on: Date.new(2022, 11, 15), end_precision: "day")
      expect(user.dossier_credentials.find_by!(title: "LabVIEW Basic I").dates).to eq("2002")
      expect(result.created["Credential"]).to include("Certified ScrumMaster", "Exchange semester")
    end

    it "Folds the thesis into its degree's description and imports the exchange semester as a Course" do
      import(as: user, text: known_credentials_yaml).import!

      expect(user.dossier_credentials.find_by!(title: "Master of Science degree in Engineering Physics").description)
        .to eq("Thesis: Algorithms for decoding Multichannel Television Sound, supervised at San Diego State University (2000).")
      expect(user.dossier_credentials.where("title LIKE ?", "%Thesis%")).to be_empty
      expect(user.dossier_credentials.find_by!(title: "Exchange semester").credential_type).to eq(course_type)
    end

    it "Notes a Certification's renewals in its description" do
      import(as: user, text: known_credentials_yaml).import!

      expect(user.dossier_credentials.find_by!(title: "Certified ScrumMaster").description).to eq("Renewed 2017.")
    end

    it "Imports each Assignment's terse achievements in file order, restricted, at importance 3" do
      import.import!

      assignment = admin.dossier_engagements.find_by!(position_title: "Test Consultant").assignments.sole
      expect(assignment.achievements.map(&:text)).to eq([ "Did a thing", "Did another thing" ])
      expect(assignment.achievements).to all(have_attributes(importance: 3, classification: "restricted", user_id: admin.id))
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
      expect(import(text: "- just\n- a list\n").preview.errors)
        .to eq([ "Not a master list: expected profile, organisations, skills, engagements or credentials" ])
    end

    it "Skips a Credential without a usable date, with a warning" do
      result = import(as: user, text: known_credentials_yaml).import!

      expect(result.warnings).to include("Credential Presentation Technique: no year or date — skipped",
                                         "Credential Anthropic Academy courses: no year or date — skipped")
      expect(user.dossier_credentials.find_by(title: "Presentation Technique")).to be_nil
    end

    it "Stops a non-admin from creating an unknown Credential Type" do
      result = import(as: user, text: credentials_yaml).preview

      expect(result.errors).to eq([ "Credential Agile Testing Workshop: unknown Credential Type 'Workshop' — ask an Admin to add it" ])
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
      expect(result.existing["Organisation"]).to contain_exactly("Acme Consulting", "Department of Examples", "Widget Works")
      expect(result.existing["Assignment"].size).to eq(3) # two share the label "Test Lead at Widget Works"
      expect(result.existing["Achievement"]).to eq([ "Did a thing", "Did another thing" ])
      expect(Dossier::Assignment.count).to eq(3)
      expect(Dossier::Achievement.count).to eq(2)
    end

    it "Adds new achievements to an Assignment that already exists" do
      import.import!
      longer = yaml.sub(/^( *)- Did a thing\n/) { "#{$&}#{$1}- Did a third thing\n" }

      result = import(text: longer).import!

      expect(result.created).to eq("Achievement" => [ "Did a third thing" ])
      assignment = admin.dossier_engagements.find_by!(position_title: "Test Consultant").assignments.sole
      expect(assignment.achievements.map(&:text)).to eq([ "Did a thing", "Did another thing", "Did a third thing" ])
    end

    it "Keeps edits made in the app on a re-import" do
      import.import!
      Dossier::Organisation.find_by!(name: "Department of Examples").update!(description: "Edited.")

      import.import!

      expect(Dossier::Organisation.find_by!(name: "Department of Examples").description).to eq("Edited.")
    end

    it "Skips Credentials that already exist, matched by title, and keeps their edits" do
      text = known_credentials_yaml
      import(as: user, text: text).import!
      user.dossier_credentials.find_by!(title: "LabVIEW Basic I").update!(description: "Edited in the app")

      result = import(as: user, text: text.sub("LabVIEW Basic I", "labview basic i")).import!

      expect(result.created).to be_empty
      expect(result.existing["Credential"]).to include("LabVIEW Basic I")
      expect(user.dossier_credentials.find_by!(title: "LabVIEW Basic I").description).to eq("Edited in the app")
    end

    it "Lets a row name its own type, and an Admin create a missing one" do
      result = import(text: credentials_yaml).import!

      expect(result).to be_ok
      expect(admin.dossier_credentials.find_by!(title: "Agile Testing Workshop").credential_type.name).to eq("Workshop")
      expect(result.created["Credential Type"]).to eq([ "Workshop" ])
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

    it "Doesn't bring back an achievement deleted in the app" do
      import.import!
      Dossier::Achievement.find_by!(text: "Did a thing").soft_delete!

      result = import.import!

      expect(result.created).to be_empty
      expect(Dossier::Achievement.kept.pluck(:text)).to eq([ "Did another thing" ])
    end

    it "Matches an achievement by its exact text only" do
      import.import!
      Dossier::Achievement.find_by!(text: "Did a thing").update!(text: "Did a thing, reworded")

      result = import.import!

      expect(result.created).to eq("Achievement" => [ "Did a thing" ])
    end

    it "Leaves out LinkedIn's education and learning lists, and an issuer of '?'" do
      import(text: credentials_yaml).import!

      expect(admin.dossier_credentials.pluck(:title)).not_to include("Blackebergs gymnasium", "Scrum: The Basics")
      expect(admin.dossier_credentials.find_by!(title: "Agile Testing Workshop").provider).to be_nil
      expect(Dossier::Organisation.find_by(name: "?")).to be_nil
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

    it "Gives a permanent Engagement's own Assignment month precision when it lists only a month" do
      text = yaml.sub("start: 2010-03-15\n        end: 2014-06", "start: 2010-04\n        end: 2014-06")

      import(text: text).import!

      first = admin.dossier_engagements.find_by!(position_title: "Test Engineer").assignments.order(:start_on).first
      expect([ first.start_on, first.start_precision ]).to eq([ Date.new(2010, 4, 1), "month" ])
      expect(import(text: text).preview.created).to be_empty
    end
  end
end
