# spec/services/dossier/private_details_export_spec.rb

require "rails_helper"

# Colleagues (an Assignment's or an Engagement's), Vendors, Customers and their Staff are private (Block 12): no CV — master or
# CV Variant, Word or PDF — may ever carry them.
RSpec.describe "Dossier private Assignment details on exports" do
  let(:user) { create(:user, :content_creator) }
  let(:today) { Date.new(2026, 11, 6) }
  let(:secrets) do
    [ "Zelda Secretname", "Quiet Lead", "zelda@hidden.example", "linkedin.com/in/zelda-secret",
      "Knows where the bodies are", "Hidden Vendor Pty", "Built the secret portal", "Hidden Customer Co", "Uses it quietly",
      "Vera Vendorstaff", "Release Wrangler", "vera@vendor.example", "linkedin.com/in/vera-secret",
      "Never ships on Fridays", "Bea Benchmate", "Bench Buddy", "Shared the bench in 2024" ]
  end

  before do
    create(:dossier_profile, user: user, display_name: "Alex Example", summary: "Test lead.")
    engagement = create(:dossier_engagement, :current, user: user, position_title: "Test Consultant")
    assignment = create(:dossier_assignment, engagement: engagement, end_month: "", project: "Alpha",
                                             test_tools_na: false, test_tools_text: "Jira")
    create(:dossier_achievement, assignment: assignment, text: "Ran daily defect triage", importance: 5)
    zelda = create(:person, user: user, first_name: "Zelda", last_name: "Secretname", work_email: "zelda@hidden.example",
                            linkedin_url: "https://linkedin.com/in/zelda-secret")
    create(:dossier_colleague, assignment: assignment, person: zelda, position: "Quiet Lead", comment: "Knows where the bodies are")
    vendor = create(:dossier_assignment_partner, assignment: assignment, scope: "Built the secret portal",
                                                 organisation: create(:dossier_organisation, name: "Hidden Vendor Pty"))
    vera = create(:person, user: user, first_name: "Vera", last_name: "Vendorstaff", work_email: "vera@vendor.example",
                           linkedin_url: "https://linkedin.com/in/vera-secret")
    create(:dossier_staff_member, assignment_partner: vendor, person: vera, position: "Release Wrangler",
                                  comment: "Never ships on Fridays")
    create(:dossier_engagement_colleague, engagement: engagement, name: "Bea Benchmate", position: "Bench Buddy",
                                          comment: "Shared the bench in 2024")
    create(:dossier_assignment_partner, :customer, assignment: assignment, scope: "Uses it quietly",
                                                   organisation: create(:dossier_organisation, name: "Hidden Customer Co"))
  end

  def docx_text(cv) = docx_parts(Dossier::CvDocx.new(cv).render).values.join("\n")
  def html_text(cv) = ApplicationController.render(template: "dossier/master_cvs/cv", layout: false, assigns: { cv: cv })

  def expect_no_secrets(text)
    secrets.each { |secret| expect(text).not_to include(secret), "expected the export not to include #{secret.inspect}" }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Keeps them out of the master CV's Word file and PDF, which still carry the CV" do
      cv = Dossier::CvDocument.new(user, today: today)

      expect(docx_text(cv)).to include("Ran daily defect triage")
      expect(html_text(cv)).to include("Ran daily defect triage")
      expect_no_secrets(docx_text(cv))
      expect_no_secrets(html_text(cv))
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Keeps them out of a CV Variant that ticks everything and shows the Tech Stack" do
      variant = create(:dossier_cv_variant, user: user, show_tech_stack: true, min_importance: 1)
      cv = Dossier::CvDocument.new(user, today: today, variant: variant)

      expect_no_secrets(docx_text(cv))
      expect_no_secrets(html_text(cv))
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Keeps them out even when the Assignment is public" do
      Dossier::Assignment.update_all(classification: "unrestricted")

      expect_no_secrets(docx_text(Dossier::CvDocument.new(user, today: today)))
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows a Vendor that is also a Client only as the Client, never with its Vendor scope" do
      vendor = Dossier::Organisation.find_by!(name: "Hidden Vendor Pty")
      Dossier::Assignment.sole.update!(client: vendor)
      text = docx_text(Dossier::CvDocument.new(user, today: today))

      expect(text).to include("Hidden Vendor Pty - Alpha")
      expect(text).not_to include("Built the secret portal")
    end
  end
end
