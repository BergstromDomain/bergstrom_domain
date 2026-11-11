# spec/features/dossier/colleagues_spec.rb
require "rails_helper"

# An Assignment's Colleagues are People (Occasions): found by name and linked,
# or added as a new Restricted Person. Their name, Work Email and LinkedIn are
# the Person's; position and comment are this Assignment's.
RSpec.describe "Dossier Assignment Colleagues", type: :feature do
  let(:charlie)    { create(:user, :content_creator) }
  let(:engagement) { create(:dossier_engagement, user: charlie) }
  let(:assignment) { create(:dossier_assignment, engagement: engagement, client: create(:dossier_organisation, name: "Westpac")) }

  def panel = find("[data-testid='assignment-colleagues']")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds a Colleague who isn't in People yet, as a new Restricted Person" do
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      within(panel) { click_link "Add A Colleague" }

      expect(page).to have_selector("h1.page-title", text: "Add A Colleague")
      expect(page).not_to have_field("Mobile")
      fill_in "First Name", with: "Anna"
      fill_in "Last Name", with: "Andersson"
      fill_in "Email", with: "anna@example.com"
      fill_in "LinkedIn", with: "https://www.linkedin.com/in/anna"
      fill_in "Position", with: "Test Lead"
      fill_in "Comment", with: "Ran the UAT team"
      click_button "Add Colleague"

      expect(page).to have_current_path(dossier_assignment_path(assignment))
      expect(page).to have_css("[data-testid='flash-success']", text: "Anna Andersson has been successfully created")
      row = panel.find("[data-testid='colleague-row']")
      expect(row).to have_link("Anna Andersson", href: person_path(Person.find_by!(first_name: "Anna")))
      expect(row).to have_text("Test Lead")
      expect(row).to have_link("anna@example.com", href: "mailto:anna@example.com")
      expect(row).to have_link("LinkedIn", href: "https://www.linkedin.com/in/anna")
      expect(row).to have_text("Ran the UAT team")
      expect(Person.find_by!(first_name: "Anna")).to have_attributes(user: charlie, classification: "restricted",
                                                                     work_email: "anna@example.com")
    end

    it "Finds someone already in People and links them, showing their details" do
      anna = create(:person, user: charlie, first_name: "Anna", last_name: "Andersson", work_email: "anna@example.com")
      sign_in_as(charlie)
      visit new_dossier_assignment_colleague_path(assignment, q: "anna and")

      within("[data-testid='person-search-results']") { click_link "Select" }
      expect(page).to have_css("[data-testid='linked-person']", text: "Linked to Anna Andersson")
      expect(page).not_to have_css("[data-testid='person-search-panel']")
      expect(page).to have_field("Email", with: "anna@example.com")
      fill_in "Position", with: "Developer"
      click_button "Add Colleague"

      expect(panel.find("[data-testid='colleague-row']")).to have_text("Developer")
      expect(assignment.colleagues.sole.person).to eq(anna)
      expect(Person.count).to eq(1)
    end

    it "Edits the Person's details and the position from the Colleague, then deletes the Colleague but not the Person" do
      colleague = create(:dossier_colleague, assignment: assignment, name: "Anna Andersson")
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)
      within(panel) { click_link "Edit" }
      fill_in "Email", with: "anna@work.example"
      fill_in "Position", with: "Test Manager"
      click_button "Save Colleague"

      expect(panel).to have_text("Test Manager")
      expect(colleague.person.reload.work_email).to eq("anna@work.example")
      within(panel) { click_button "Delete" }
      expect(page).to have_css("[data-testid='flash-success']", text: "Anna Andersson has been successfully deleted")
      expect(panel).to have_selector("[data-testid='colleagues-empty']")
      expect(Person.exists?(colleague.person_id)).to be(true)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a first name for a new Person" do
      sign_in_as(charlie)
      visit new_dossier_assignment_colleague_path(assignment)
      click_button "Add Colleague"

      expect(page).to have_selector("[data-testid='field-error']", text: "First name can't be blank")
      expect(Dossier::Colleague.count).to eq(0)
    end

    it "Keeps you on Edit with the error when the Person's Work Email isn't one" do
      colleague = create(:dossier_colleague, assignment: assignment, name: "Anna Andersson")
      sign_in_as(charlie)
      visit edit_dossier_assignment_colleague_path(assignment, colleague)
      fill_in "Email", with: "anna-at-example"
      click_button "Save Colleague"

      expect(page).to have_selector("[data-testid='form-errors']", text: "Work email is invalid")
      expect(colleague.person.reload.work_email).to be_nil
    end

    it "Won't add a second Person of the same name" do
      create(:person, user: charlie, first_name: "Anna", last_name: "Andersson")
      sign_in_as(charlie)
      visit new_dossier_assignment_colleague_path(assignment)
      fill_in "First Name", with: "anna"
      fill_in "Last Name", with: "andersson"
      click_button "Add Colleague"

      expect(page).to have_selector("[data-testid='form-errors']", text: "Full name has already been taken")
      expect(page).to have_css("[data-testid='person-search-panel']")
      expect(Person.count).to eq(1)
    end

    it "Finds only People you can see, and won't link another's Restricted Person by id" do
      hidden = create(:person, first_name: "Hilda", last_name: "Hidden", classification: "restricted")
      sign_in_as(charlie)
      visit new_dossier_assignment_colleague_path(assignment, q: "Hilda")

      expect(page).to have_css("[data-testid='person-search-empty']", text: "No one in People called “Hilda”")
      visit new_dossier_assignment_colleague_path(assignment, person_id: hidden.id)
      expect(page).not_to have_css("[data-testid='linked-person']")
      expect(find_field("First Name").value).to be_blank
    end

    it "Hides the panel from anyone but the owner and Admins, even on a public Assignment" do
      assignment.update!(classification: "unrestricted")
      create(:dossier_colleague, assignment: assignment, name: "Anna Andersson")
      sign_in_as(create(:user, :content_creator))
      visit dossier_assignment_path(assignment)

      expect(page).to have_selector("[data-testid='show-panel-metadata']")
      expect(page).not_to have_selector("[data-testid='assignment-colleagues']")
      expect(page).not_to have_text("Anna Andersson")
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
      create(:dossier_colleague, assignment: assignment, name: "Anna Andersson")
      sign_in_as(create(:user, :admin))
      visit dossier_assignment_path(assignment)

      expect(panel).to have_text("Anna Andersson")
    end

    it "Links someone else's visible Person, showing their details without letting you change them" do
      chris = create(:user, :content_creator, first_name: "Chris")
      bertil = create(:person, :unrestricted, user: chris, first_name: "Bertil", last_name: "Berg",
                                              work_email: "bertil@example.com")
      sign_in_as(charlie)
      visit new_dossier_assignment_colleague_path(assignment, person_id: bertil.id)

      readonly = find("[data-testid='person-details-readonly']")
      expect(readonly).to have_text("Only Chris and Admins can change this Person's details.")
      expect(readonly).to have_link("bertil@example.com")
      expect(page).not_to have_field("First Name")
      click_button "Add Colleague"

      expect(assignment.colleagues.sole.person).to eq(bertil)
    end

    it "Finds People as you type and links the one you select", js: true do
      anna = create(:person, user: charlie, first_name: "Anna", last_name: "Andersson")
      sign_in_as(charlie)
      visit new_dossier_assignment_colleague_path(assignment)
      find("[data-testid='person-search-input']").fill_in(with: "ander")

      expect(page).to have_css("[data-testid='person-search-row']", text: "Anna Andersson")
      js_click("select-person-#{anna.id}")
      expect(page).to have_css("[data-testid='linked-person']", text: "Linked to Anna Andersson")
    end

    it "Goes back to the search to choose someone else" do
      anna = create(:person, user: charlie, first_name: "Anna", last_name: "Andersson")
      sign_in_as(charlie)
      visit new_dossier_assignment_colleague_path(assignment, person_id: anna.id)
      click_link "Choose Someone Else"

      expect(page).to have_css("[data-testid='person-search-panel']")
      expect(find_field("First Name").value).to be_blank
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

    it "Searches only once there are two letters" do
      create(:person, user: charlie, first_name: "Anna", last_name: "Andersson")
      sign_in_as(charlie)
      visit new_dossier_assignment_colleague_path(assignment, q: "A")

      expect(page).not_to have_css("[data-testid='person-search-row']")
      expect(page).not_to have_css("[data-testid='person-search-empty']")
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
