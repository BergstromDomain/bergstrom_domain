# spec/services/dossier/cv_docx_spec.rb

require "rails_helper"

RSpec.describe Dossier::CvDocx do
  let(:user) { create(:user, :content_creator) }

  def paragraphs
    docx_paragraphs(described_class.new(Dossier::CvDocument.new(user, today: Date.new(2026, 11, 5))).render)
  end

  def texts_in(style) = paragraphs.select { |s, _| s == style }.map(&:last)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Lays out the header, summary, Experience, Skills and Credentials in the Classic styles" do
      create(:dossier_profile, user: user, display_name: "Alex Example", headline: "Test Lead",
                               email: "alex@example.com", phone: "0400 000 000", summary_first_person: "I lead test teams.")
      job = create(:dossier_engagement, user: user, position_title: "Test Consultant",
                                        employer: create(:dossier_organisation, name: "Bridge"),
                                        employment_type: create(:dossier_employment_type, name: "Consultant"))
      assignment = create(:dossier_assignment, engagement: job, client: create(:dossier_organisation, name: "Westpac"),
                                               role: create(:dossier_role, name: "Test Lead"),
                                               test_tools_na: false, test_tools_text: "Jira")
      create(:dossier_achievement, assignment: assignment, text: "Ran daily defect triage", impact: "cut defects by 40%")
      create(:dossier_credential, :certification, user: user, title: "ISTQB Foundation",
                                                  provider: create(:dossier_organisation, name: "ISTQB"))

      expect(paragraphs.first(4)).to eq([ [ "Title", "Alex Example" ], [ "Subtitle", "Test Lead" ],
                                          [ "Contacts", "alex@example.com · 0400 000 000" ], [ nil, "I lead test teams." ] ])
      expect(texts_in("Heading1")).to eq([ "Experience", "Skills", "Certifications" ])
      expect(texts_in("Heading2")).to eq([ "Test Consultant" ])
      expect(texts_in("Heading3")).to eq([ "Westpac" ])
      expect(texts_in("Meta")).to eq([ "Bridge · Consultant · Mar 2019 – Jun 2022", "Test Lead · Mar 2019 – Jun 2022" ])
      expect(texts_in("TechStack")).to eq([ "Test Tools: Jira" ])
      expect(texts_in("ListBullet")).to eq([ "Ran daily defect triage — cut defects by 40%" ])
      expect(paragraphs.last).to eq([ nil, "ISTQB Foundation · ISTQB · Mar 2020" ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves out empty sections and a missing headline, contacts and summary" do
      create(:dossier_profile, user: user, display_name: "Alex Example")

      expect(paragraphs).to eq([ [ "Title", "Alex Example" ] ])
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Puts personal Engagements under Personal Projects and marks an expired Credential" do
      create(:dossier_profile, user: user)
      create(:dossier_engagement, :personal, user: user, position_title: "Home Lab")
      create(:dossier_credential, :certification, user: user, title: "Old Cert", expires_month: "2021-01")

      expect(texts_in("Heading1")).to eq([ "Personal Projects", "Certifications" ])
      expect(texts_in("Heading2")).to eq([ "Home Lab" ])
      expect(paragraphs.last.last).to start_with("Old Cert (expired)")
    end

    it "Shows a folded permanent job's Achievements with no Assignment heading" do
      create(:dossier_profile, user: user)
      job = create(:dossier_engagement, :permanent, user: user, position_title: "QA Engineer")
      create(:dossier_achievement, assignment: job.assignments.first, text: "Automated the smoke tests")

      expect(texts_in("Heading3")).to be_empty
      expect(texts_in("ListBullet")).to eq([ "Automated the smoke tests" ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Writes the owner's name in the footer and the document properties" do
      create(:dossier_profile, user: user, display_name: "Alex Example")
      parts = docx_parts(described_class.new(Dossier::CvDocument.new(user)).render)

      expect(parts.fetch("word/footer1.xml")).to include("Alex Example · Page")
      expect(parts.fetch("docProps/core.xml")).to include("<dc:title>Alex Example — CV</dc:title>")
    end
  end
end
