# spec/features/dossier/contributions_spec.rb
require "rails_helper"

# Contributions: talks, articles and other community work, on their own and
# not part of any Engagement or Assignment, though one can say which
# Engagement it was made during.
RSpec.describe "Dossier Contributions", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let!(:meetup) { create(:dossier_organisation, name: "All Things Testing Brisbane") }
  let(:elysium) do
    create(:dossier_engagement, user: charlie, position_title: "Test Manager",
                                employer: create(:dossier_organisation, name: "Elysium Digital"), start_month: "2024-09", end_month: "")
  end

  def table(kind) = find("[data-testid='contributions-#{kind}']")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds a talk with its event, date, Skills and poster, from the left nav" do
      elysium
      sign_in_as(charlie)
      visit dossier_contributions_path
      within("[data-testid='left-nav']") { click_link "Add A Contribution" }

      select "Talk", from: "Kind"
      fill_in "Title", with: "Getting Started with Robot Framework"
      select "All Things Testing Brisbane", from: "Event"
      fill_in "Date Year", with: "2024"
      select "November", from: "Date Month"
      fill_in "Date Day", with: "19"
      fill_in "Location", with: "Gold Tower, Level 27, 10 Eagle St, Brisbane City"
      fill_in "Presented As", with: "Test Manager, Elysium Digital"
      fill_in "Link", with: "https://www.meetup.com/all-things-testing-brisbane/"
      fill_in "Technical Skills", with: "Robot Framework, Knowledge Sharing"
      select "Test Manager at Elysium Digital (Sep 2024 – Present)", from: "During"
      attach_file "Files", file_fixture("test_image.png")
      click_button "Add Contribution"

      expect(page).to have_css("[data-testid='flash-success']", text: "Getting Started with Robot Framework has been successfully created")
      expect(page).to have_selector("h1", text: "Getting Started with Robot Framework")
      expect(page).to have_selector("[data-testid='contribution-kind']", text: "Talk")
      expect(page).to have_link("All Things Testing Brisbane", href: dossier_organisation_path(meetup))
      expect(page).to have_selector("[data-testid='contribution-date']", text: "19 Nov 2024")
      expect(page).to have_selector("[data-testid='contribution-location']", text: "Gold Tower")
      expect(page).to have_selector("[data-testid='contribution-presented-as']", text: "Test Manager, Elysium Digital")
      expect(page).to have_link("https://www.meetup.com/all-things-testing-brisbane/")
      expect(page).to have_link("Test Manager at Elysium Digital", href: dossier_engagement_path(elysium))
      expect(page).to have_link("Robot Framework")
      expect(page).to have_selector("[data-testid='contribution-files'] img")
    end

    it "Lists them by kind, newest first" do
      create(:dossier_contribution, user: charlie, title: "Statistical Methods in Software Testing", start_month: "2023-04", event: meetup)
      create(:dossier_contribution, user: charlie, title: "Getting Started with Robot Framework", start_month: "2024-11")
      create(:dossier_contribution, user: charlie, kind: "article", title: "Why Flaky Tests Lie", start_month: "2025-02")
      create(:dossier_contribution, title: "Someone Else's Talk")
      sign_in_as(charlie)
      visit dossier_contributions_path

      expect(all("[data-testid='contribution-group-heading']").map(&:text)).to eq(%w[Talks Articles])
      expect(table("talk").all("[data-testid='contribution-title']").map(&:text))
        .to eq([ "Getting Started with Robot Framework", "Statistical Methods in Software Testing" ])
      expect(table("talk")).to have_text("All Things Testing Brisbane")
      expect(page).not_to have_text("Someone Else's Talk")
    end

    it "Edits one, then deletes and restores it" do
      talk = create(:dossier_contribution, user: charlie, title: "Statistical Methods")
      sign_in_as(charlie)
      visit dossier_contribution_path(talk)
      click_link "Edit Contribution"
      fill_in "Title", with: "Statistical Methods in Software Testing"
      click_button "Save Contribution"

      expect(page).to have_css("[data-testid='flash-success']", text: "Statistical Methods in Software Testing has been successfully updated")
      click_button "Delete Contribution"
      expect(page).to have_current_path(dossier_contributions_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Statistical Methods in Software Testing has been successfully deleted")
      expect(page).to have_selector("[data-testid='empty-state']")

      visit deleted_dossier_contributions_path
      expect(page).to have_selector("[data-testid='deleted-contribution-row']", text: "Statistical Methods in Software Testing")
      find("[data-testid='restore-contribution-#{talk.id}']").click
      expect(page).to have_css("[data-testid='flash-success']", text: "Statistical Methods in Software Testing has been successfully restored")
      expect(talk.reload.deleted_at).to be_nil
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Keeps you on the form with the errors" do
      sign_in_as(charlie)
      visit new_dossier_contribution_path
      fill_in "Link", with: "meetup.com/talk"
      click_button "Add Contribution"

      errors = find("[data-testid='form-errors']")
      expect(errors).to have_text("Title can't be blank")
      expect(errors).to have_text("Link must start with http:// or https://")
      expect(Dossier::Contribution.count).to eq(0)
    end

    it "Offers only your own Engagements as During" do
      create(:dossier_engagement, position_title: "Someone Else's Job")
      elysium
      sign_in_as(charlie)
      visit new_dossier_contribution_path

      expect(page).to have_select("During", with_options: [ "Test Manager at Elysium Digital (Sep 2024 – Present)" ])
      expect(page).not_to have_select("During", with_options: [ "Someone Else's Job" ], wait: 0)
    end

    it "Hides Edit and Delete, and the files, from another creator on an Unrestricted one" do
      talk = create(:dossier_contribution, user: charlie, classification: "unrestricted",
                                           files: [ Rack::Test::UploadedFile.new(file_fixture("test_image.png"), "image/png") ])
      sign_in_as(create(:user, :content_creator))
      visit dossier_contribution_path(talk)

      expect(page).to have_selector("h1", text: talk.title)
      expect(page).not_to have_link("Edit Contribution")
      expect(page).not_to have_button("Delete Contribution")
      expect(page).not_to have_selector("[data-testid='contribution-files']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Takes just a year, with no event or During" do
      sign_in_as(charlie)
      visit new_dossier_contribution_path
      select "Article", from: "Kind"
      fill_in "Title", with: "Why Flaky Tests Lie"
      fill_in "Date Year", with: "2025"
      click_button "Add Contribution"

      expect(page).to have_selector("[data-testid='contribution-date']", text: "2025")
      expect(page).to have_selector("[data-testid='contribution-event']", text: "—")
      expect(page).to have_selector("[data-testid='contribution-engagement']", text: "None")
    end

    it "Removes a saved file when it's unticked" do
      talk = create(:dossier_contribution, user: charlie, files: [ Rack::Test::UploadedFile.new(file_fixture("test_image.png"), "image/png") ])
      sign_in_as(charlie)
      visit edit_dossier_contribution_path(talk)
      uncheck "Keep test_image.png"
      click_button "Save Contribution"

      expect(page).not_to have_selector("[data-testid='contribution-files']")
      expect(talk.reload.files).not_to be_attached
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Says there are none yet" do
      sign_in_as(charlie)
      visit dossier_contributions_path

      expect(page).to have_selector("[data-testid='empty-state']", text: "No Contributions yet.")
      expect(page).to have_link("Add A Contribution", href: new_dossier_contribution_path)
    end

    it "Shows the Deleted page's days remaining, and only your own" do
      talk = create(:dossier_contribution, user: charlie, title: "Old Talk")
      talk.update_columns(deleted_at: 10.days.ago)
      create(:dossier_contribution, title: "Not Mine").update_columns(deleted_at: 1.day.ago)
      sign_in_as(charlie)
      visit deleted_dossier_contributions_path

      expect(page).to have_selector("[data-testid='deleted-contribution-row']", count: 1)
      expect(page).to have_selector("[data-testid='deleted-contribution-days-remaining']", text: "20")
    end
  end
end
