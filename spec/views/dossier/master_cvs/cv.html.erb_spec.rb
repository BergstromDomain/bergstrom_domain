# spec/views/dossier/master_cvs/cv.html.erb_spec.rb
require "rails_helper"

RSpec.describe "dossier/master_cvs/cv", type: :view do
  let(:user) { create(:user, :content_creator) }

  def render_cv
    assign(:cv, Dossier::CvDocument.new(user, today: Date.new(2026, 11, 5)))
    render template: "dossier/master_cvs/cv", layout: false
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the header, summary, Experience, Skills, Credentials and Contributions" do
      create(:dossier_profile, user: user, display_name: "Alex Example", headline: "Test Lead",
                               email: "alex@example.com", summary_first_person: "I lead test teams.")
      job = create(:dossier_engagement, user: user, position_title: "Test Consultant",
                                        employer: create(:dossier_organisation, name: "Bridge"))
      assignment = create(:dossier_assignment, engagement: job, client: create(:dossier_organisation, name: "Westpac"),
                                               test_tools_na: false, test_tools_text: "Jira")
      create(:dossier_achievement, assignment: assignment, text: "Ran daily defect triage")
      create(:dossier_credential, :certification, user: user, title: "ISTQB Foundation")
      create(:dossier_contribution, user: user, title: "Statistical Methods", start_precision: "month",
                                    event: create(:dossier_organisation, name: "All Things Testing"))

      render_cv

      expect(rendered).to have_css("h1.cv-name", text: "Alex Example")
      expect(rendered).to have_css(".cv-headline", text: "Test Lead")
      expect(rendered).to have_css(".cv-contacts", text: "alex@example.com")
      expect(rendered).to have_css(".cv-summary", text: "I lead test teams.")
      within_section = ->(heading) { Capybara.string(rendered).find("section", text: heading) }
      expect(within_section.("Experience")).to have_css(".cv-job-title", text: "Test Consultant")
      expect(within_section.("Experience")).to have_css(".cv-assignment-heading", text: "Westpac")
      expect(within_section.("Experience")).to have_css(".cv-tech-stack", text: "Test Tools: Jira")
      expect(within_section.("Experience")).to have_css("li", text: "Ran daily defect triage")
      expect(rendered).to have_css("h2", text: "Skills")
      expect(rendered).to have_css("h2", text: "Certifications")
      expect(rendered).to have_css(".cv-credential", text: "ISTQB Foundation")
      expect(within_section.("Presentations & Community")).to have_css(".cv-contribution", text: "Statistical Methods — All Things Testing, Nov 2024")
      expect(rendered.index("Certifications")).to be < rendered.index("Presentations &amp; Community")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves out sections with nothing in them" do
      create(:dossier_profile, user: user)

      render_cv

      expect(rendered).not_to have_css("h2", text: "Experience")
      expect(rendered).not_to have_css("h2", text: "Personal Projects")
      expect(rendered).not_to have_css("h2", text: "Skills")
      expect(rendered).not_to have_css(".cv-summary")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows personal Engagements under Personal Projects and marks an expired Credential" do
      create(:dossier_profile, user: user)
      create(:dossier_engagement, :personal, user: user, position_title: "Home Lab")
      create(:dossier_credential, :certification, user: user, title: "Old Cert", expires_month: "2021-01")

      render_cv

      expect(rendered).to have_css("h2", text: "Personal Projects")
      expect(rendered).to have_css(".cv-job-title", text: "Home Lab")
      expect(rendered).to have_css(".cv-credential", text: "Old Cert (expired)")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Escapes HTML typed into the CV's text" do
      create(:dossier_profile, user: user, summary: "<script>alert(1)</script>")

      render_cv

      expect(rendered).not_to include("<script>alert(1)</script>")
      expect(rendered).to include("&lt;script&gt;")
    end
  end
end
