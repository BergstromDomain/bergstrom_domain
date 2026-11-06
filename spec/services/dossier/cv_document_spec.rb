# spec/services/dossier/cv_document_spec.rb

require "rails_helper"

RSpec.describe Dossier::CvDocument do
  let(:user)  { create(:user, :content_creator) }
  let(:today) { Date.new(2026, 11, 5) }
  let(:cv)    { described_class.new(user, today: today) }

  def profile(**attributes)
    create(:dossier_profile, user: user, display_name: "Alex Example", **attributes)
  end

  def engagement(*traits, **attributes)
    create(:dossier_engagement, *traits, user: user, **attributes)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Heads the CV with the name, headline and contact details" do
      profile(headline: "Senior Test Consultant", location: create(:dossier_location, city: "Sydney", country: "Australia"),
              email: "alex@example.com", phone: "+61 400 000 000", website_url: "https://alex.example",
              linkedin_url: "https://linkedin.com/in/alex", github_url: "https://github.com/alex")

      expect(cv.header.name).to eq("Alex Example")
      expect(cv.header.headline).to eq("Senior Test Consultant")
      expect(cv.header.contacts).to eq([ "Sydney, Australia", "alex@example.com", "+61 400 000 000", "https://alex.example",
                                         "https://linkedin.com/in/alex", "https://github.com/alex" ])
    end

    it "Uses the first-person summary" do
      profile(summary: "Test lead.", summary_first_person: "I lead test teams.")

      expect(cv.summary).to eq("I lead test teams.")
    end

    it "Lists Engagements newest first, each with its Assignments, Tech Stack and Achievements" do
      profile
      older = engagement(position_title: "Tester", employer: create(:dossier_organisation, name: "Acme"),
                         start_month: "2015-01", end_month: "2017-12")
      newer = engagement(position_title: "Test Consultant", employer: create(:dossier_organisation, name: "Bridge"),
                         employment_type: create(:dossier_employment_type, name: "Consultant"),
                         start_month: "2019-03", end_month: "2022-06", summary: "Consulting for banks.")
      assignment = create(:dossier_assignment, engagement: newer, client: create(:dossier_organisation, name: "Westpac", abbreviation: "WBC"),
                                               project: "Payments", role: create(:dossier_role, name: "Test Lead"),
                                               location: create(:dossier_location, city: "Sydney", country: "Australia"),
                                               start_month: "2019-03", end_month: "2020-12", summary: "Led payments testing.",
                                               test_tools_na: false, test_tools_text: "Jira, qTest")
      create(:dossier_achievement, assignment: assignment, text: "Ran daily defect triage", impact: "cut open defects by 40%")
      create(:dossier_achievement, assignment: assignment, text: "Built the regression suite")
      create(:dossier_assignment, engagement: older, start_month: "2015-01", end_month: "2017-12")

      expect(cv.experience.map(&:title)).to eq([ "Test Consultant", "Tester" ])
      job = cv.experience.first
      expect(job).to have_attributes(organisation: "Bridge", employment_type: "Consultant",
                                     dates: "Mar 2019 – Jun 2022", summary: "Consulting for banks.")
      expect(job.assignments.first).to have_attributes(
        heading: "WBC - Payments", role: "Test Lead", dates: "Mar 2019 – Dec 2020", location: "Sydney, Australia",
        summary: "Led payments testing.", tech_stack: [ [ "Test Tools", "Jira, qTest" ] ],
        achievements: [ "Ran daily defect triage — cut open defects by 40%", "Built the regression suite" ]
      )
    end

    it "Groups Skills by Skill Category" do
      profile
      tools = create(:dossier_skill_category, name: "Test Tools")
      create(:dossier_skill, name: "Jira", skill_category: tools)
      create(:dossier_skill, name: "Agile", skill_category: create(:dossier_skill_category, name: "Methodologies"))
      create(:dossier_assignment, engagement: engagement, test_tools_na: false, test_tools_text: "Jira",
                                  methodologies_na: false, methodologies_text: "Agile")

      expect(cv.skills).to eq([ [ "Methodologies", [ "Agile" ] ], [ "Test Tools", [ "Jira" ] ] ])
    end

    it "Shows a Skill's versions as one family, in the order first used, in Skills and the Tech Stack" do
      profile
      systems = create(:dossier_skill_category, name: "Operating Systems")
      windows = create(:dossier_skill, name: "Windows", skill_category: systems)
      linux = create(:dossier_skill, name: "Linux", skill_category: systems)
      create(:dossier_skill, name: "Windows Vista", parent: windows)
      create(:dossier_skill, name: "Windows XP", parent: windows)
      job = engagement(start_month: "2005-01", end_month: "2012-12")
      create(:dossier_assignment, engagement: job, start_month: "2005-01", end_month: "2007-12",
                                  operating_systems_na: false, operating_systems_text: "Windows XP, Linux")
      create(:dossier_assignment, engagement: job, start_month: "2008-01", end_month: "2012-12",
                                  operating_systems_na: false, operating_systems_text: "Windows Vista, Windows XP, Windows")

      expect(cv.skills).to eq([ [ "Operating Systems", [ "Windows (XP, Vista)", "Linux" ] ] ])
      stacks = cv.experience.first.assignments.map(&:tech_stack)
      expect(stacks).to eq([ [ [ "Operating Systems", "Windows (XP, Vista)" ] ], [ [ "Operating Systems", "Windows (XP), Linux" ] ] ])
      expect(linux.versions).to be_empty
    end

    it "Shows a family with only the CV Variant's versions" do
      profile
      windows = create(:dossier_skill, name: "Windows", skill_category: create(:dossier_skill_category, name: "Operating Systems"))
      vista = create(:dossier_skill, name: "Windows Vista", parent: windows)
      create(:dossier_skill, name: "Windows XP", parent: windows)
      create(:dossier_assignment, engagement: engagement, operating_systems_na: false,
                                  operating_systems_text: "Windows (XP, Vista)")
      variant = create(:dossier_cv_variant, user: user)
      variant.items.create!(item: vista, included: false)

      expect(described_class.new(user, today: today, variant: variant).skills).to eq([ [ "Operating Systems", [ "Windows (XP)" ] ] ])
    end

    it "Groups Credentials by Credential Type in type order, all training types together" do
      profile
      degree = create(:dossier_credential_type, name: "Degree", position: 1)
      certification = create(:dossier_credential_type, name: "Certification", position: 3)
      create(:dossier_credential_type, :training, name: "Course", position: 4)
      workshop = create(:dossier_credential_type, :training, name: "Workshop", position: 5)
      create(:dossier_credential, user: user, credential_type: workshop, title: "Exploratory Testing Workshop")
      create(:dossier_credential, user: user, title: "Agile Fundamentals") # Course, training
      create(:dossier_credential, user: user, credential_type: certification, title: "ISTQB Foundation",
                                  provider: create(:dossier_organisation, name: "ISTQB"))
      create(:dossier_credential, user: user, credential_type: degree, title: "BSc Computer Science",
                                  start_month: "2001", end_month: "2004")

      expect(cv.credentials.map(&:heading)).to eq([ "Degrees", "Certifications", "Training" ])
      expect(cv.credentials.first.entries.first).to have_attributes(title: "BSc Computer Science", dates: "2001 – 2004")
      expect(cv.credentials.second.entries.first).to have_attributes(title: "ISTQB Foundation", provider: "ISTQB", expired: false)
      expect(cv.credentials.third.entries.map(&:title)).to contain_exactly("Exploratory Testing Workshop", "Agile Fundamentals")
    end

    it "Names the file after the display name and today's date" do
      profile(display_name: "Alex Q. Example")

      expect(cv.filename("docx")).to eq("Alex_Q_Example_CV_2026-11-05.docx")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Has no Profile, so no CV, when none has been created" do
      expect(cv.profile?).to be(false)
    end

    it "Leaves out other users' Engagements and Credentials" do
      profile
      create(:dossier_engagement, position_title: "Someone Else's Job")
      create(:dossier_credential, title: "Someone Else's Course")

      expect(cv.experience).to be_empty
      expect(cv.credentials).to be_empty
    end

    it "Leaves out deleted Engagements and Achievements, and N/A Tech Stack lists" do
      profile
      engagement(position_title: "Deleted Job").soft_delete!
      assignment = create(:dossier_assignment, engagement: engagement)
      create(:dossier_achievement, assignment: assignment, text: "Kept")
      create(:dossier_achievement, assignment: assignment, text: "Deleted").soft_delete!

      expect(cv.experience.map(&:title)).to eq([ "Test Consultant" ])
      expect(cv.experience.first.assignments.first).to have_attributes(achievements: [ "Kept" ], tech_stack: [])
    end

    it "Leaves out what a CV Variant leaves out: low-importance Achievements, Training, unticked items" do
      profile
      variant = create(:dossier_cv_variant, user: user, min_importance: 3)
      job = engagement(:current, position_title: "Test Consultant")
      assignment = create(:dossier_assignment, engagement: job, test_tools_na: false, test_tools_text: "Jira")
      create(:dossier_achievement, assignment: assignment, text: "Important", importance: 4)
      create(:dossier_achievement, assignment: assignment, text: "Minor", importance: 2)
      create(:dossier_credential, user: user, title: "A Course")
      cert = create(:dossier_credential, :certification, user: user, title: "Unticked Cert")
      variant.items.create!(item: cert, included: false)

      cv = described_class.new(user, today: today, variant: variant)

      expect(cv.experience.first.assignments.first.achievements).to eq([ "Important" ])
      expect(cv.experience.first.assignments.first.tech_stack).to eq([])
      expect(cv.credentials).to be_empty
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Filters through a CV Variant: older Engagements condensed, its summary, Tech Stack when asked, its own filename" do
      profile(summary: "Test lead.")
      variant = create(:dossier_cv_variant, user: user, name: "QE Lead — Acme", summary_override: "For Acme.",
                                            show_tech_stack: true)
      old = engagement(position_title: "Tester", start_month: "2010-01", end_month: "2015-12", summary: "Old job.")
      create(:dossier_assignment, engagement: old, start_month: "2010-01", end_month: "2015-12")
      recent = engagement(:current, position_title: "Test Consultant")
      create(:dossier_assignment, engagement: recent, end_month: "", test_tools_na: false, test_tools_text: "Jira")

      cv = described_class.new(user, today: today, variant: variant)

      expect(cv.summary).to eq("For Acme.")
      expect(cv.experience.map(&:title)).to eq([ "Test Consultant", "Tester" ])
      expect(cv.experience.second).to have_attributes(assignments: [], summary: nil, dates: "Jan 2010 – Dec 2015")
      expect(cv.experience.first.assignments.first.tech_stack).to eq([ [ "Test Tools", "Jira" ] ])
      expect(cv.filename("pdf")).to eq("Alex_Example_CV_QE_Lead_Acme_2026-11-05.pdf")
    end

    it "Keeps only the CV Variant's Skills" do
      profile
      variant = create(:dossier_cv_variant, user: user)
      tools = create(:dossier_skill_category, name: "Test Tools")
      jira = create(:dossier_skill, name: "Jira", skill_category: tools)
      create(:dossier_skill, name: "qTest", skill_category: tools)
      create(:dossier_assignment, engagement: engagement, test_tools_na: false, test_tools_text: "Jira, qTest")
      variant.items.create!(item: jira, included: false)

      expect(described_class.new(user, today: today, variant: variant).skills).to eq([ [ "Test Tools", [ "qTest" ] ] ])
    end

    it "Falls back to the terse summary" do
      profile(summary: "Test lead.")

      expect(cv.summary).to eq("Test lead.")
    end

    it "Puts personal Engagements under Personal Projects, not Experience" do
      profile
      engagement(position_title: "Test Consultant")
      engagement(:personal, position_title: "Home Lab", employer: create(:dossier_organisation, name: "Self"))

      expect(cv.experience.map(&:title)).to eq([ "Test Consultant" ])
      expect(cv.personal_projects.map(&:title)).to eq([ "Home Lab" ])
    end

    it "Folds a permanent job's single synced Assignment into its Engagement" do
      profile
      job = engagement(:permanent, position_title: "QA Engineer")
      create(:dossier_achievement, assignment: job.assignments.first, text: "Automated the smoke tests")

      expect(job.assignments.size).to eq(1)
      expect(cv.experience.first.assignments.first).to have_attributes(heading: nil, role: nil, dates: nil,
                                                                        achievements: [ "Automated the smoke tests" ])
    end

    it "Marks an expired Credential, and shows an unfinished one as in progress" do
      profile
      create(:dossier_credential, :certification, user: user, title: "Old Cert", expires_month: "2021-01")
      create(:dossier_credential, user: user, title: "Ongoing Course", end_month: "")

      entries = cv.credentials.flat_map(&:entries)
      expect(entries.find { |e| e.title == "Old Cert" }.expired).to be(true)
      expect(entries.find { |e| e.title == "Ongoing Course" }.dates).to eq("Mar 2020 – in progress")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves out contact details that aren't set" do
      profile(email: "alex@example.com")

      expect(cv.header.contacts).to eq([ "alex@example.com" ])
    end

    it "Shows a current Engagement as running to Present, and a remote Assignment as Remote" do
      profile
      job = engagement(:current)
      create(:dossier_assignment, engagement: job, end_month: "", remote: true,
                                  location: create(:dossier_location, city: "Perth", country: "Australia"))

      expect(cv.experience.first.dates).to eq("Mar 2019 – Present")
      expect(cv.experience.first.assignments.first.location).to eq("Perth, Australia (Remote)")
    end

    it "Has empty sections, not errors, for a Profile with nothing else" do
      profile

      expect([ cv.experience, cv.personal_projects, cv.skills, cv.credentials ]).to all(be_empty)
    end

    it "Shows a Personal Project a CV Variant ticks" do
      profile
      variant = create(:dossier_cv_variant, user: user)
      lab = engagement(:personal, :current, position_title: "Home Lab")
      variant.items.create!(item: lab, included: true)

      expect(described_class.new(user, today: today, variant: variant).personal_projects.map(&:title)).to eq([ "Home Lab" ])
    end

    it "Strips characters a filename can't safely hold" do
      profile(display_name: "Åsa O'Brien / Test")

      expect(cv.filename("pdf")).to eq("Åsa_O_Brien_Test_CV_2026-11-05.pdf")
    end
  end
end
