# spec/features/dossier/assignment_page_spec.rb
require "rails_helper"

# The layout of an Assignment's page: title, Summary, Engagement details,
# Achievements, Tech Stack, Training and the private Colleagues frame.
RSpec.describe "Dossier Assignment page", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }

  let!(:apa) do
    create(:dossier_organisation, name: "APA Group", abbreviation: "APA",
                                  description: "Australia's largest natural gas infrastructure business.")
  end
  let(:engagement) { create(:dossier_engagement, user: charlie, start_month: "2019-01", end_month: "2020-12") }

  let(:testing)    { create(:dossier_skill_category, name: "Testing", position: 1) }
  let(:management) { create(:dossier_skill_category, name: "Test & Issue Management", parent: testing, position: 2) }
  let(:systems)    { create(:dossier_skill_category, name: "Operating Systems", position: 2) }
  let(:databases)  { create(:dossier_skill_category, name: "Databases", position: 3) }
  let(:queries)    { create(:dossier_skill_category, name: "Query Languages", parent: databases, position: 1) }
  let(:sut)        { create(:dossier_skill_category, name: "System Under Test") }

  let(:assignment) do
    create(:dossier_skill, name: "Energy Components", skill_category: sut)
    create(:dossier_skill, name: "SSRS", skill_category: sut)
    create(:dossier_skill, name: "Quality Center", skill_category: management)
    create(:dossier_skill, name: "PL/SQL", skill_category: queries)
    windows = create(:dossier_skill, name: "Windows", skill_category: systems)
    create(:dossier_skill, name: "XP", skill_category: systems, parent: windows)
    create(:dossier_assignment, engagement: engagement, client: apa, classification: "unrestricted",
                                project: "Energy Components Upgrade",
                                summary: "Led all testing for the upgrade of Energy Components.",
                                systems_under_test_na: false, systems_under_test_text: "Energy Components, SSRS",
                                test_tools_na: false, test_tools_text: "Quality Center",
                                other_tools_na: false, other_tools_text: "PL/SQL",
                                operating_systems_na: false, operating_systems_text: "Windows (XP)")
  end

  def summary = find("[data-testid='assignment-summary-panel']")
  def blocks = all("[data-testid='tech-stack-block']")
  def columns(block) = block.all("th").map(&:text)
  def cells(block) = block.all("td").map(&:text)
  def panel_order = all(".show-panel[data-testid]").map { |panel| panel["data-testid"] }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Titles the page 'Client - Project' and shows the Summary: client, project, System Under Test, Vendor and Customer" do
      create(:dossier_assignment_partner, assignment: assignment, organisation: create(:dossier_organisation, name: "Quorum"))
      create(:dossier_assignment_partner, :customer, assignment: assignment,
                                                     organisation: create(:dossier_organisation, name: "AEMO"))
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      expect(page).to have_selector("h1.page-title", exact_text: "APA Group - Energy Components Upgrade")
      expect(summary).to have_selector("[data-testid='assignment-client-description']",
                                       text: "Australia's largest natural gas infrastructure business.")
      expect(summary).to have_selector("[data-testid='assignment-summary']",
                                       text: "Led all testing for the upgrade of Energy Components.")
      within(summary.find("[data-testid='assignment-systems-under-test']")) do
        expect(page).to have_link("Energy Components")
        expect(page).to have_link("SSRS")
      end
      expect(summary.find("[data-testid='assignment-vendors']")).to have_link("Quorum")
      expect(summary.find("[data-testid='assignment-customers']")).to have_link("AEMO")
    end

    it "Shows the frames in order: Summary, Engagement, Achievements, Tech Stack, Training, Colleagues" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      expect(panel_order).to eq(%w[assignment-summary-panel show-panel-metadata assignment-achievements tech-stack
                                   training-panel assignment-colleagues show-panel-actions])
      expect(page).to have_selector("[data-testid='assignment-client']", text: "APA Group (APA)")
      expect(page).to have_selector("[data-testid='assignment-project']", text: "Energy Components Upgrade")
    end

    it "Shows the Tech Stack as a table per category, in order, with a column per sub-category" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      expect(blocks.map { |block| columns(block) }).to eq([
        [ "Testing", "Test & Issue Management" ], [ "Operating Systems" ], [ "Databases", "Query Languages" ]
      ])
      expect(blocks.map { |block| cells(block) }).to eq([ [ "", "Quality Center" ], [ "Windows (XP)" ], [ "", "PL/SQL" ] ])
      within(find("[data-testid='tech-stack']")) do
        expect(page).not_to have_text("Energy Components")
        expect(page).to have_link("Windows")
        click_link "XP"
      end
      expect(page).to have_selector("[data-testid='reference-data-name']", text: "XP")
    end

    it "Shows Training as a table: Title, Issued By, Dates and Skills" do
      create(:dossier_credential, user: charlie, engagement: engagement, assignment: assignment,
                                  title: "Excel VBA Essential Training", provider: create(:dossier_organisation, name: "LinkedIn Learning"),
                                  start_month: "2019-05", end_month: "2019-05", skills_text: "Excel VBA")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      within("[data-testid='training-panel']") do
        expect(all("th").map(&:text)).to eq([ "Title", "Issued By", "Dates", "Skills" ])
        expect(find("[data-testid='training-row']").all("td").map(&:text))
          .to eq([ "Excel VBA Essential Training", "LinkedIn Learning", "May 2019", "Excel VBA" ])
        expect(page).to have_link("Excel VBA")
      end
    end

    it "Groups Colleagues, Vendors and Customers in one Colleagues frame: Client, Vendor, Customer" do
      create(:dossier_colleague, assignment: assignment, name: "Ava Client")
      vendor = create(:dossier_assignment_partner, assignment: assignment, organisation: create(:dossier_organisation, name: "Quorum"))
      create(:dossier_staff_member, assignment_partner: vendor, name: "Ben Vendor")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      within("[data-testid='assignment-colleagues']") do
        # Each heading's first word: Vendor and Customer carry an info tip.
        expect(all("h3.show-panel__subheading").map { |heading| heading.text[/\A\w+/] }).to eq(%w[Client Vendor Customer])
        expect(find("[data-testid='colleagues-table']")).to have_text("Ava Client")
        expect(find("[data-testid='vendors']")).to have_text("Ben Vendor")
        expect(find("[data-testid='customers']")).to have_text("No Customers yet.")
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Hides the Vendor, Customer and Colleagues from another Content Creator" do
      create(:dossier_assignment_partner, assignment: assignment, organisation: create(:dossier_organisation, name: "Quorum"))
      sign_in_as(chris)
      visit dossier_assignment_path(assignment)

      expect(summary).to have_selector("[data-testid='assignment-summary']")
      expect(summary).not_to have_selector("[data-testid='assignment-vendors']")
      expect(page).not_to have_text("Quorum")
      expect(page).not_to have_selector("[data-testid='assignment-colleagues']")
    end

    it "Sends Gary Guest to sign in" do
      visit dossier_assignment_path(assignment)

      expect(page).to have_current_path(new_session_path)
      expect(page).not_to have_text("APA Group")
    end

    it "Hides the Vendor and Customer from the Summary when there are none" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      expect(summary).not_to have_selector("[data-testid='assignment-vendors']")
      expect(summary).not_to have_selector("[data-testid='assignment-customers']")
    end

    it "Hides the Tech Stack when only the System Under Test has Skills" do
      assignment.update!(test_tools_na: true, test_tools_text: "", other_tools_na: true, other_tools_text: "",
                         operating_systems_na: true, operating_systems_text: "")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      expect(page).not_to have_selector("[data-testid='tech-stack']")
      expect(summary.find("[data-testid='assignment-systems-under-test']")).to have_link("SSRS")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Shows an Admin the Vendor and Customer in the Summary" do
      create(:dossier_assignment_partner, :customer, assignment: assignment,
                                                     organisation: create(:dossier_organisation, name: "AEMO"))
      sign_in_as(create(:user, :admin))
      visit dossier_assignment_path(assignment)

      expect(summary.find("[data-testid='assignment-customers']")).to have_link("AEMO")
      expect(summary).not_to have_selector("[data-testid='assignment-vendors']")
    end

    it "Titles the page by the client alone, leaving out an empty description and summary" do
      client = create(:dossier_organisation, name: "Northwind")
      bare = create(:dossier_assignment, engagement: engagement, client: client, project: nil, summary: nil)
      sign_in_as(charlie)
      visit dossier_assignment_path(bare)

      expect(page).to have_selector("h1.page-title", exact_text: "Northwind")
      expect(summary).not_to have_selector("[data-testid='assignment-client-description']")
      expect(summary).not_to have_selector("[data-testid='assignment-summary']")
      expect(summary.find("[data-testid='assignment-systems-under-test']")).to have_text("N/A")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows Training with no Issued By or Skills as dashes" do
      create(:dossier_credential, user: charlie, engagement: engagement, assignment: assignment, title: "Agile Basics",
                                  start_month: "2019-05", end_month: "2019-05")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      expect(find("[data-testid='training-row']").all("td").map(&:text)).to eq([ "Agile Basics", "—", "May 2019", "—" ])
    end
  end
end
