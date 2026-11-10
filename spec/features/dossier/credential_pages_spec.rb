# spec/features/dossier/credential_pages_spec.rb
require "rails_helper"

# The Credentials pages' layout: collapsible frames with headers, the Courses
# table (Completed only, sortable, Issued By links to Browse Courses), Taken
# During's "Personal Development" default, a Credential's Show frames and its
# certificate previews, and the Browse / Filter Courses views.
RSpec.describe "Dossier Credential pages", type: :feature do
  let(:charlie) { create(:user, :content_creator, first_name: "Charlie", last_name: "Creator") }
  let(:chris)   { create(:user, :content_creator) }

  let!(:degree) { create(:dossier_credential_type, name: "Degree", position: 1) }
  let!(:course) { create(:dossier_credential_type, :training, name: "Course", position: 4) }
  let!(:linkedin) { create(:dossier_organisation, name: "LinkedIn Learning") }
  let!(:udemy)    { create(:dossier_organisation, name: "Udemy") }

  def add_course(title, provider: linkedin, **attributes)
    create(:dossier_credential, user: charlie, credential_type: course, title: title, provider: provider, **attributes)
  end

  def group(name) = find("details[data-testid='credential-group']", text: name)
  def titles(scope = page) = scope.all("[data-testid='credential-row'] td:first-child").map { |cell| cell.text.strip }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows each type in an open frame with a header, Courses listing only Completed ones" do
      create(:dossier_credential, user: charlie, credential_type: degree, title: "MSc Engineering Physics")
      add_course("Learning Docker")
      add_course("Learning Chef", status: "in_progress", end_on: nil)
      add_course("Learning Puppet", status: "todo", start_on: nil, end_on: nil)
      sign_in_as(charlie)
      visit dossier_credentials_path

      expect(all("details[data-testid='credential-group']").map { |frame| frame.find("summary").text })
        .to eq(%w[Degree Course])
      expect(all("details[data-testid='credential-group']").map { |frame| frame[:open] }).to all(be_truthy)
      expect(titles(group("Course"))).to eq([ "Learning Docker" ])
    end

    it "Sorts the Courses table by a column, reversing on a second click" do
      add_course("Learning Docker", provider: udemy, start_on: Date.new(2018, 5, 1), end_on: Date.new(2018, 5, 1))
      add_course("Ansible Essentials", start_on: Date.new(2020, 1, 1), end_on: Date.new(2020, 1, 1))
      sign_in_as(charlie)
      visit dossier_credentials_path

      click_link "Title"
      expect(titles).to eq([ "Ansible Essentials", "Learning Docker" ])
      click_link "Title"
      expect(titles).to eq([ "Learning Docker", "Ansible Essentials" ])
      click_link "Issued By"
      expect(titles).to eq([ "Ansible Essentials", "Learning Docker" ])
      click_link "Dates"
      expect(titles).to eq([ "Learning Docker", "Ansible Essentials" ])
    end

    it "Links Issued By to Browse Courses at that provider" do
      add_course("Learning Docker")
      sign_in_as(charlie)
      visit dossier_credentials_path
      within(group("Course")) { click_link "LinkedIn Learning" }

      expect(page).to have_current_path(dossier_browse_courses_path(provider_id: linkedin.to_param))
      expect(page).to have_selector("[data-testid='browse-preview-heading']", text: "Courses in LinkedIn Learning (1)")
    end

    it "Shows '<name> Personal Development' as Taken During for a stand-alone Credential" do
      add_course("Learning Docker")
      sign_in_as(charlie)
      visit dossier_credentials_path

      expect(find("[data-testid='credential-taken-during']")).to have_text("Charlie Creator Personal Development")
      click_link "Learning Docker"
      expect(find("[data-testid='credential-taken-during']")).to have_text("Charlie Creator Personal Development")
    end

    it "Sets a status on Edit, which takes a Course off the Credentials list" do
      add_course("Learning Docker")
      sign_in_as(charlie)
      visit dossier_credentials_path
      click_link "Learning Docker"
      click_link "Edit Credential"
      select "To Do", from: "Status"
      fill_in "Completed Year", with: ""
      select "Choose a month", from: "Completed Month"
      click_button "Update Credential"

      expect(find("[data-testid='credential-status']")).to have_text("To Do")
      visit dossier_credentials_path
      expect(page).not_to have_link("Learning Docker")
    end

    it "Shows a Credential's frames with headers, all open" do
      add_course("Learning Docker", description: "Containers from scratch.", certificate_number: "AZ-1")
      sign_in_as(charlie)
      visit dossier_credential_path(Dossier::Credential.last)

      frames = all("details.show-panel")
      expect(frames.map { |frame| frame.find("summary").text }).to eq(%w[Description Details Verification])
      expect(frames.map { |frame| frame[:open] }).to all(be_truthy)
    end

    it "Previews an image and a PDF certificate for the owner" do
      credential = add_course("Learning Docker")
      credential.files.attach([ fixture_file_upload("test_image.png", "image/png"),
                                fixture_file_upload("test_certificate.pdf", "application/pdf") ])
      sign_in_as(charlie)
      visit dossier_credential_path(credential)

      within("[data-testid='credential-files']") do
        expect(find("img[data-testid='certificate-preview-image']")[:src])
          .to end_with(dossier_credential_file_path(credential, credential.files.first))
        expect(find("iframe[data-testid='certificate-preview-pdf']")[:src])
          .to end_with(dossier_credential_file_path(credential, credential.files.second))
        expect(page).to have_link("test_certificate.pdf")
      end
    end

    it "Browses Courses by provider, every status, with the status shown" do
      add_course("Learning Docker")
      add_course("Learning Chef", status: "in_progress", end_on: nil)
      add_course("Rails 5", provider: udemy)
      sign_in_as(charlie)
      visit dossier_browse_courses_path

      expect(page).to have_selector("[data-testid='browse-root']", text: "Browse Courses")
      click_link "LinkedIn Learning"
      within("[data-testid='browse-preview']") do
        expect(titles).to contain_exactly("Learning Docker", "Learning Chef")
        expect(find("tr", text: "Learning Chef")).to have_selector("[data-testid='credential-status']", text: "In Progress")
      end
    end

    it "Filters Courses by provider and status, in a sortable table" do
      add_course("Learning Docker")
      add_course("Learning Chef", status: "in_progress", end_on: nil)
      add_course("Rails 5", provider: udemy, status: "in_progress", end_on: nil)
      sign_in_as(charlie)
      visit dossier_filter_courses_path
      select "LinkedIn Learning", from: "Issued By"
      select "In Progress", from: "Status"
      click_button "Apply Filters"

      expect(titles).to eq([ "Learning Chef" ])
      expect(page).to have_selector("[data-testid='filter-count']", text: "1 Course")
      expect(page).to have_link("Title")
    end

    it "Lists Credentials, Browse Courses and Filter Courses under a Credentials group in the left nav" do
      sign_in_as(charlie)
      visit dossier_credentials_path

      within("[data-testid='left-nav-credentials-h3'] + a") { expect(page).to have_text("Credentials") }
      expect(page).to have_link("Browse Courses", href: dossier_browse_courses_path)
      expect(page).to have_link("Filter Courses", href: dossier_filter_courses_path)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows no certificate preview to another Content Creator, even on an Unrestricted Credential" do
      credential = add_course("Learning Docker", classification: "unrestricted")
      credential.files.attach(fixture_file_upload("test_image.png", "image/png"))
      sign_in_as(chris)
      visit dossier_credential_path(credential)

      expect(page).to have_selector("[data-testid='credential-title']", text: "Learning Docker")
      expect(page).not_to have_selector("[data-testid='certificate-preview-image']")
    end

    it "Shows the error for Completed without a Completed date, keeping the form" do
      credential = add_course("Learning Chef", status: "in_progress", end_on: nil)
      sign_in_as(charlie)
      visit edit_dossier_credential_path(credential)
      select "Completed", from: "Status"
      click_button "Update Credential"

      expect(page).to have_selector("[data-testid='field-error']", text: "is needed when the status is Completed")
      expect(credential.reload).to be_in_progress
    end

    it "Never lists another user's Courses in Browse or Filter Courses" do
      create(:dossier_credential, user: chris, credential_type: course, title: "Chris's Course", provider: linkedin)
      add_course("Learning Docker")
      sign_in_as(charlie)
      visit dossier_browse_courses_path(provider_id: linkedin.to_param)
      expect(page).not_to have_text("Chris's Course")

      visit dossier_filter_courses_path
      expect(page).to have_link("Learning Docker")
      expect(page).not_to have_text("Chris's Course")
    end

    it "Ignores an unknown sort column" do
      add_course("B Course", start_on: Date.new(2020, 1, 1), end_on: Date.new(2020, 1, 1))
      add_course("A Course", start_on: Date.new(2019, 1, 1), end_on: Date.new(2019, 1, 1))
      sign_in_as(charlie)
      visit dossier_credentials_path(sort: "hacked", direction: "sideways")

      expect(titles).to eq([ "B Course", "A Course" ])
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Hides the Verification frame when both fields are empty, keeping them on Edit" do
      credential = add_course("Learning Docker")
      sign_in_as(charlie)
      visit dossier_credential_path(credential)

      expect(page).not_to have_selector("[data-testid='show-panel-proof']")
      click_link "Edit Credential"
      expect(page).to have_field("Credential ID")
      expect(page).to have_field("Verification URL")
    end

    it "Shows the Description frame with 'No description yet.' when empty" do
      sign_in_as(charlie)
      visit dossier_credential_path(add_course("Learning Docker"))

      expect(find("[data-testid='show-panel-main']")).to have_text("No description yet.")
    end

    it "Still links Taken During to the Engagement when there is one" do
      engagement = create(:dossier_engagement, user: charlie, position_title: "Test Analyst")
      add_course("Learning Docker", engagement: engagement)
      sign_in_as(charlie)
      visit dossier_credentials_path

      expect(find("[data-testid='credential-taken-during']")).to have_link(engagement.to_toast_label)
    end

    it "Collapses a frame on a click and reopens it on reload", js: true do
      add_course("Learning Docker")
      sign_in_as(charlie)
      visit dossier_credentials_path
      group("Course").find("summary").click

      expect(page).not_to have_link("Learning Docker")
      visit dossier_credentials_path
      expect(page).to have_link("Learning Docker")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows an empty state in the Courses frame when none are Completed" do
      add_course("Learning Chef", status: "in_progress", end_on: nil)
      sign_in_as(charlie)
      visit dossier_credentials_path

      expect(group("Course")).to have_selector("[data-testid='empty-state']",
                                               text: "No Completed Courses. Filter Courses lists the rest.")
    end

    it "Lines the tables' columns up with the same fixed widths" do
      create(:dossier_credential, user: charlie, credential_type: degree, title: "MSc")
      add_course("Learning Docker")
      sign_in_as(charlie)
      visit dossier_credentials_path

      expect(all("table[data-testid='credentials-table']").map { |table| table.all("col").map { |col| col[:class] } }.uniq)
        .to eq([ %w[dossier-credentials-col--title dossier-credentials-col--provider dossier-credentials-col--dates
                    dossier-credentials-col--taken-during dossier-credentials-col--skills] ])
    end

    it "Shows a To Do Course's dates as a dash in Filter Courses" do
      add_course("Learning Puppet", status: "todo", start_on: nil, end_on: nil)
      sign_in_as(charlie)
      visit dossier_filter_courses_path

      expect(find("[data-testid='credential-row']").all("td")[2].text).to eq("—")
    end

    it "Sends Gary Guest to sign in from Browse and Filter Courses" do
      visit dossier_browse_courses_path
      expect(page).to have_current_path(new_session_path)
      visit dossier_filter_courses_path
      expect(page).to have_current_path(new_session_path)
    end
  end
end
