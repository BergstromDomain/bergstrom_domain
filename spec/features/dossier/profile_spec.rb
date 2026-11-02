# spec/features/dossier/profile_spec.rb
require "rails_helper"

RSpec.describe "Dossier Profile", type: :feature do
  let(:charlie)  { create(:user, :content_creator, first_name: "Charlie", last_name: "Content Creator") }
  let(:uno)      { create(:user) }
  let!(:falun)   { create(:dossier_location, city: "Falun", country: "Sweden") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Starts a Content Creator's profile from their name and saves it with a toast" do
      sign_in_as(charlie)
      visit dossier_profile_path
      expect(page).to have_current_path(edit_dossier_profile_path)
      expect(page).to have_field("Display Name", with: "Charlie Content Creator")

      fill_in "Headline", with: "Test Manager"
      select "Falun, Sweden", from: "Location"
      fill_in "Email", with: "charlie@example.com"
      fill_in "Summary", with: "Test manager with 25+ years in software testing."
      click_button "Save Profile"

      expect(page).to have_current_path(dossier_profile_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Charlie Content Creator has been successfully created")
      expect(page).to have_selector("[data-testid='profile-headline']", text: "Test Manager")
      expect(page).to have_selector("[data-testid='profile-location']", text: "Falun, Sweden")
      expect(page).to have_selector("[data-testid='profile-summary']", text: "Test manager with 25+ years")
    end

    it "Updates an existing profile with a toast" do
      create(:dossier_profile, user: charlie, display_name: "Charlie Content Creator")
      sign_in_as(charlie)
      visit dossier_profile_path
      click_link "Edit Profile"
      fill_in "Headline", with: "Portfolio Test Manager"
      click_button "Save Profile"

      expect(page).to have_css("[data-testid='flash-success']", text: "Charlie Content Creator has been successfully updated")
      expect(page).to have_selector("[data-testid='profile-headline']", text: "Portfolio Test Manager")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error and saves nothing without a display name" do
      sign_in_as(charlie)
      visit edit_dossier_profile_path
      fill_in "Display Name", with: ""
      click_button "Save Profile"

      expect(page).to have_selector("[data-testid='field-error']", text: "can't be blank")
      expect(Dossier::Profile.count).to eq(0)
    end

    it "Sends 'Gary Guest' to the 'Sign in' page" do
      visit dossier_profile_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Sends 'Uno User' back to the Dossier landing page" do
      sign_in_as(uno)
      visit dossier_profile_path
      expect(page).to have_current_path(dossier_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Saves optional first- and third-person summaries and the third-person settings" do
      sign_in_as(charlie)
      visit edit_dossier_profile_path
      fill_in "Summary", with: "Test manager with 25+ years."
      fill_in "First-Person Summary", with: "I am a test manager with 25+ years."
      fill_in "Third-Person Summary", with: "Charlie is a test manager with 25+ years."
      fill_in "Third-Person Name", with: "Charlie"
      select "She/Her", from: "Pronouns"
      click_button "Save Profile"

      expect(page).to have_selector("[data-testid='profile-summary-first-person']", text: "I am a test manager")
      expect(page).to have_selector("[data-testid='profile-summary-third-person']", text: "Charlie is a test manager")
      expect(page).to have_selector("[data-testid='profile-pronouns']", text: "She/Her")
    end

    it "Explains the three summaries in an info tip, on the Profile and its form" do
      create(:dossier_profile, user: charlie, display_name: "Charlie Content Creator")
      sign_in_as(charlie)
      visit dossier_profile_path
      expect(page).to have_selector("[data-testid='profile-summary-info']", text: "First-Person Summary speaks as you", visible: :all)

      click_link "Edit Profile"
      expect(page).to have_selector("[data-testid='summary-info']", visible: :all)
    end

    it "Puts the Website, LinkedIn and GitHub links on their own row" do
      create(:dossier_profile, user: charlie, display_name: "Charlie Content Creator",
                               website_url: "https://example.com", github_url: "https://github.com/example")
      sign_in_as(charlie)
      visit dossier_profile_path

      rows = all("[data-testid='profile-meta-row']")
      expect(rows.size).to eq(2)
      expect(rows.last.all(".show-meta-cell__label").map(&:text)).to eq(%w[Website LinkedIn GitHub])
      expect(rows.last).to have_link("https://github.com/example")
    end

    it "Is reachable from the left nav's My Career group" do
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") { click_link "Profile" }
      expect(page).to have_current_path(edit_dossier_profile_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows only the signed-in user's own profile" do
      create(:dossier_profile, display_name: "Chris Content Creator")
      create(:dossier_profile, user: charlie, display_name: "Charlie Content Creator")
      sign_in_as(charlie)
      visit dossier_profile_path

      expect(page).to have_selector("h1.page-title", text: "Charlie Content Creator")
      expect(page).not_to have_content("Chris Content Creator")
    end

    it "Hides My Career from an App User's left nav" do
      sign_in_as(uno)
      visit dossier_path
      expect(page).not_to have_selector("[data-testid='left-nav-my-career-h3']")
    end
  end
end
