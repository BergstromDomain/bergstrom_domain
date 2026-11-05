# spec/features/dossier/colleagues_spec.rb
require "rails_helper"

RSpec.describe "Dossier Assignment Colleagues", type: :feature do
  let(:charlie)    { create(:user, :content_creator) }
  let(:engagement) { create(:dossier_engagement, user: charlie) }
  let(:assignment) { create(:dossier_assignment, engagement: engagement, client: create(:dossier_organisation, name: "Westpac")) }

  def panel = find("[data-testid='assignment-colleagues']")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds a Colleague from the Assignment page and lists their details there" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      within(panel) { click_link "Add A Colleague" }

      expect(page).to have_selector("h1.page-title", text: "Add A Colleague")
      fill_in "Name", with: "Anna Andersson"
      fill_in "Position", with: "Test Lead"
      fill_in "Mobile", with: "+61 400 000 000"
      fill_in "Email", with: "anna@example.com"
      fill_in "LinkedIn", with: "https://linkedin.com/in/anna"
      fill_in "Comment", with: "Ran the UAT team"
      click_button "Add Colleague"

      expect(page).to have_current_path(dossier_assignment_path(assignment))
      expect(page).to have_css("[data-testid='flash-success']", text: "Anna Andersson has been successfully created")
      row = panel.find("[data-testid='colleague-row']")
      expect(row).to have_text("Anna Andersson")
      expect(row).to have_text("Test Lead")
      expect(row).to have_text("+61 400 000 000")
      expect(row).to have_link("anna@example.com", href: "mailto:anna@example.com")
      expect(row).to have_link("LinkedIn", href: "https://linkedin.com/in/anna")
      expect(row).to have_text("Ran the UAT team")
    end

    it "Edits and deletes a Colleague" do
      create(:dossier_colleague, assignment: assignment, name: "Anna")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      within(panel) { click_link "Edit" }
      fill_in "Position", with: "Test Manager"
      click_button "Save Colleague"

      expect(panel).to have_text("Test Manager")
      within(panel) { click_button "Delete" }
      expect(page).to have_css("[data-testid='flash-success']", text: "Anna has been successfully deleted")
      expect(panel).to have_selector("[data-testid='colleagues-empty']")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a name" do
      sign_in_as(charlie)
      visit new_dossier_assignment_colleague_path(assignment)
      click_button "Add Colleague"

      expect(page).to have_selector("[data-testid='field-error']", text: "can't be blank")
    end

    it "Hides the panel from anyone but the owner and Admins, even on a public Assignment" do
      assignment.update!(classification: "unrestricted")
      create(:dossier_colleague, assignment: assignment, name: "Anna")
      sign_in_as(create(:user, :content_creator))
      visit dossier_assignment_path(assignment)

      expect(page).to have_selector("[data-testid='show-panel-metadata']")
      expect(page).not_to have_selector("[data-testid='assignment-colleagues']")
      expect(page).not_to have_text("Anna")
    end

    it "Turns away another user from the Colleague forms" do
      colleague = create(:dossier_colleague, assignment: assignment)
      sign_in_as(create(:user, :content_creator))

      visit new_dossier_assignment_colleague_path(assignment)
      expect(page).to have_current_path(dossier_engagements_path)
      visit edit_dossier_assignment_colleague_path(assignment, colleague)
      expect(page).to have_current_path(dossier_engagements_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows an Admin the Colleagues" do
      create(:dossier_colleague, assignment: assignment, name: "Anna")
      sign_in_as(create(:user, :admin))
      visit dossier_assignment_path(assignment)

      expect(panel).to have_text("Anna")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows only a name when that's all there is" do
      create(:dossier_colleague, assignment: assignment, name: "Anna")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      expect(panel.find("[data-testid='colleague-row']")).to have_text("Anna")
      expect(panel).not_to have_link("LinkedIn")
    end

    it "Won't edit a Colleague through another Assignment's URL" do
      other = create(:dossier_assignment, engagement: engagement)
      colleague = create(:dossier_colleague, assignment: other)
      sign_in_as(charlie)

      visit edit_dossier_assignment_colleague_path(assignment, colleague)
      expect(page).to have_http_status(:not_found)
    end
  end
end
