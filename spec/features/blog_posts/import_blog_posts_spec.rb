# spec/features/blog_posts/import_blog_posts_spec.rb

require "rails_helper"

RSpec.describe "Import Blog Posts", type: :feature do
  let(:owner) { create(:user, :content_creator) }

  def csv_file_for(rows)
    content = CSV.generate(headers: true) do |csv|
      csv << BlogPostImportService::HEADERS
      rows.each { |row| csv << row }
    end

    file = Tempfile.new([ "import", ".csv" ])
    file.write(content)
    file.rewind
    file
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the import form with a template download link" do
      sign_in_as(owner)
      visit new_blog_import_path

      expect(page).to have_selector("[data-testid='import-file-input']")
      expect(page).to have_selector("[data-testid='import-template-link']", text: "Download Import Template")
    end

    it "Downloads a CSV template with the correct header row" do
      sign_in_as(owner)
      visit new_blog_import_path
      click_link "Download Import Template"

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.body.lines.first).to include(*BlogPostImportService::HEADERS)
    end

    it "Imports a CSV file and shows the results, creating posts as Drafts" do
      category = create(:blog_category, name: "Technology")
      file = csv_file_for([ [ "My Imported Post", "Technology", "Ruby", "Rails", "Some body text." ] ])

      sign_in_as(owner)
      visit new_blog_import_path
      attach_file("file", file.path)
      click_button "Import"

      expect(page).to have_selector("[data-testid='import-summary']", text: "1 row imported, 0 rows failed.")

      post = BlogPost.find_by!(title: "My Imported Post")
      expect(post.user).to eq(owner)
      expect(post.blog_category).to eq(category)
      expect(post.published?).to be false
      expect(post.classification).to eq("restricted")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit new_blog_import_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies 'Uno User' (app_user role)" do
      sign_in_as(create(:user))
      visit new_blog_import_path

      expect(page).to have_current_path(chronicle_path)
      expect(page).to have_content("Not authorised")
    end

    it "Shows an alert when no file is chosen" do
      sign_in_as(owner)
      visit new_blog_import_path
      click_button "Import"

      expect(page).to have_content("Please choose a CSV file to import.")
    end

    it "Shows an alert when the uploaded file isn't a CSV" do
      sign_in_as(owner)
      visit new_blog_import_path
      attach_file("file", Rails.root.join("spec/fixtures/files/test_image.jpg"))
      click_button "Import"

      expect(page).to have_content("The uploaded file must be a CSV file.")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows failed rows with their error messages alongside successful ones" do
      file = csv_file_for([
        [ "", "", "", "", "Body" ],
        [ "Good Post", "", "", "", "Body" ]
      ])

      sign_in_as(owner)
      visit new_blog_import_path
      attach_file("file", file.path)
      click_button "Import"

      expect(page).to have_selector("[data-testid='import-summary']", text: "1 row imported, 1 row failed.")
      expect(page).to have_selector("[data-testid='import-error-row']", text: "2")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves a post uncategorized when the CSV Category doesn't match any existing one" do
      file = csv_file_for([ [ "My Post", "No Such Category", "", "", "Body" ] ])

      sign_in_as(owner)
      visit new_blog_import_path
      attach_file("file", file.path)
      click_button "Import"

      expect(page).to have_selector("[data-testid='import-summary']", text: "1 row imported, 0 rows failed.")
      expect(BlogPost.find_by!(title: "My Post").blog_category).to be_nil
    end
  end
end
