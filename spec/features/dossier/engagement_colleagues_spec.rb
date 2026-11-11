# spec/features/dossier/engagement_colleagues_spec.rb
require "rails_helper"

# An Engagement's Colleagues: consultants you worked with during it but on no
# Assignment you shared. Like an Assignment's, they're People (Occasions),
# private to the owner and Admins, and never on a CV.
RSpec.describe "Dossier Engagement Colleagues", type: :feature do
  let(:charlie)    { create(:user, :content_creator) }
  let(:engagement) { create(:dossier_engagement, user: charlie, position_title: "Test Consultant") }

  def panel = find("[data-testid='engagement-colleagues']")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds a Colleague who isn't in People yet, as a new Restricted Person" do
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)
      within(panel) { click_link "Add A Colleague" }

      expect(page).to have_selector("h1.page-title", text: "Add A Colleague")
      expect(page).to have_link(engagement.to_toast_label, href: dossier_engagement_path(engagement))
      fill_in "First Name", with: "Anna"
      fill_in "Last Name", with: "Andersson"
      fill_in "Email", with: "anna@example.com"
      fill_in "Position", with: "Performance Tester"
      fill_in "Comment", with: "Same consultancy, different clients"
      click_button "Add Colleague"

      expect(page).to have_current_path(dossier_engagement_path(engagement))
      expect(page).to have_css("[data-testid='flash-success']", text: "Anna Andersson has been successfully created")
      row = panel.find("[data-testid='engagement-colleague-row']")
      expect(row).to have_link("Anna Andersson", href: person_path(Person.find_by!(first_name: "Anna")))
      expect(row).to have_text("Performance Tester")
      expect(row).to have_text("Same consultancy, different clients")
      expect(Person.find_by!(first_name: "Anna")).to have_attributes(user: charlie, classification: "restricted",
                                                                     work_email: "anna@example.com")
    end

    it "Finds someone already in People and links them" do
      anna = create(:person, user: charlie, first_name: "Anna", last_name: "Andersson")
      sign_in_as(charlie)
      visit new_dossier_engagement_colleague_path(engagement, q: "anders")

      within("[data-testid='person-search-results']") { click_link "Select" }
      expect(page).to have_css("[data-testid='linked-person']", text: "Linked to Anna Andersson")
      click_button "Add Colleague"

      expect(engagement.colleagues.sole.person).to eq(anna)
      expect(Person.count).to eq(1)
    end

    it "Edits a Colleague, then deletes them but not the Person" do
      colleague = create(:dossier_engagement_colleague, engagement: engagement, name: "Anna Andersson")
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)
      within(panel) { click_link "Edit" }

      expect(page).to have_selector("h1.page-title", text: "Edit Colleague")
      fill_in "Position", with: "Test Manager"
      click_button "Save Colleague"
      expect(page).to have_current_path(dossier_engagement_path(engagement))
      expect(panel).to have_text("Test Manager")

      within(panel) { click_button "Delete" }
      expect(page).to have_css("[data-testid='flash-success']", text: "Anna Andersson has been successfully deleted")
      expect(panel).to have_selector("[data-testid='engagement-colleagues-empty']")
      expect(Person.exists?(colleague.person_id)).to be(true)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a first name for a new Person" do
      sign_in_as(charlie)
      visit new_dossier_engagement_colleague_path(engagement)
      click_button "Add Colleague"

      expect(page).to have_selector("[data-testid='field-error']", text: "First name can't be blank")
      expect(Dossier::EngagementColleague.count).to eq(0)
    end

    it "Won't add the same Person twice" do
      colleague = create(:dossier_engagement_colleague, engagement: engagement, name: "Anna Andersson")
      sign_in_as(charlie)
      visit new_dossier_engagement_colleague_path(engagement, person_id: colleague.person_id)
      click_button "Add Colleague"

      expect(page).to have_selector("[data-testid='form-errors']", text: "is already a Colleague on this Engagement")
      expect(engagement.colleagues.count).to eq(1)
    end

    it "Keeps you on Edit with the error when the Person's Work Email isn't one" do
      colleague = create(:dossier_engagement_colleague, engagement: engagement, name: "Anna Andersson")
      sign_in_as(charlie)
      visit edit_dossier_engagement_colleague_path(engagement, colleague)
      fill_in "Email", with: "anna-at-example"
      click_button "Save Colleague"

      expect(page).to have_selector("[data-testid='form-errors']", text: "Work email is invalid")
    end

    it "Hides the panel from anyone but the owner and Admins, even on a public Engagement" do
      engagement.update!(classification: "unrestricted")
      create(:dossier_engagement_colleague, engagement: engagement, name: "Anna Andersson")
      sign_in_as(create(:user, :content_creator))
      visit dossier_engagement_path(engagement)

      expect(page).to have_selector("[data-testid='show-panel-metadata']")
      expect(page).not_to have_selector("[data-testid='engagement-colleagues']")
      expect(page).not_to have_text("Anna Andersson")
    end

    it "Turns away another user, and anyone from a deleted Engagement's forms" do
      colleague = create(:dossier_engagement_colleague, engagement: engagement)
      sign_in_as(create(:user, :content_creator))
      visit new_dossier_engagement_colleague_path(engagement)
      expect(page).to have_current_path(dossier_engagements_path)
      visit edit_dossier_engagement_colleague_path(engagement, colleague)
      expect(page).to have_current_path(dossier_engagements_path)

      engagement.soft_delete!
      sign_in_as(charlie)
      visit new_dossier_engagement_colleague_path(engagement)
      expect(page).to have_current_path(dossier_engagements_path)
      expect(page).to have_text("Not authorised.")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows an Admin the Colleagues, and lets them add one owned by the Engagement's owner" do
      create(:dossier_engagement_colleague, engagement: engagement, name: "Anna Andersson")
      sign_in_as(create(:user, :admin))
      visit dossier_engagement_path(engagement)
      expect(panel).to have_text("Anna Andersson")

      within(panel) { click_link "Add A Colleague" }
      fill_in "First Name", with: "Bertil"
      click_button "Add Colleague"
      expect(Person.find_by!(first_name: "Bertil").user).to eq(charlie)
    end

    it "Lets a Person be a Colleague on the Engagement and on one of its Assignments" do
      assignment = create(:dossier_assignment, engagement: engagement)
      colleague = create(:dossier_colleague, assignment: assignment, name: "Anna Andersson")
      sign_in_as(charlie)
      visit new_dossier_engagement_colleague_path(engagement, person_id: colleague.person_id)
      click_button "Add Colleague"

      expect(panel).to have_link("Anna Andersson")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Says there are none yet" do
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)

      expect(panel).to have_selector("[data-testid='engagement-colleagues-empty']", text: "No Colleagues yet.")
    end

    it "Won't edit a Colleague through another Engagement's URL" do
      other = create(:dossier_engagement, user: charlie)
      colleague = create(:dossier_engagement_colleague, engagement: other)
      sign_in_as(charlie)

      visit edit_dossier_engagement_colleague_path(engagement, colleague)
      expect(page).to have_http_status(:not_found)
    end
  end
end
