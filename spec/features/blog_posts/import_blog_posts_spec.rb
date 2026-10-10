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

  def zip_file_for(entries)
    buffer = Zip::OutputStream.write_buffer do |zip|
      entries.each do |name, content|
        zip.put_next_entry(name)
        zip.write(content)
      end
    end

    file = Tempfile.new([ "import", ".zip" ], binmode: true)
    file.write(buffer.string)
    file.rewind
    file
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the import form with a template download link" do
      sign_in_as(owner)
      visit new_blog_import_path

      expect(page).to have_selector("[data-testid='import-file-input']")
      expect(page).to have_selector("[data-testid='import-template-link']", text: "Download CSV Template")
    end

    it "Downloads a CSV template with the correct header row" do
      sign_in_as(owner)
      visit new_blog_import_path
      click_link "Download CSV Template"

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.body.lines.first).to include(*BlogPostImportService::HEADERS)
    end

    it "Imports a CSV file and shows the results, creating posts as Drafts" do
      category = create(:blog_category, name: "Technology")
      file = csv_file_for([ [ "My Imported Post", "Technology", "Ruby", "Rails", "Some body text." ] ])

      sign_in_as(owner)
      # Settle on the post-sign-in page before navigating — in a real browser
      # the `visit` below can otherwise race sign_in_as's redirect and land
      # back on the sign-in form (no file field).
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']")
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

    it "Imports a ZIP file (Markdown + image) and shows the results, creating a post as a Draft" do
      category = create(:blog_category, name: "Technology")
      file = zip_file_for(
        "My_Zip_Post.md"    => "Text\n\n![Photo](images/photo.png)",
        "images/photo.png" => "fake-png-bytes"
      )

      sign_in_as(owner)
      # Settle on the post-sign-in page before navigating — in a real browser
      # the `visit` below can otherwise race sign_in_as's redirect and land
      # back on the sign-in form (no file field).
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']")
      visit new_blog_import_path
      attach_file("file", file.path)
      find("[data-testid='import-category-select']").select("Technology")
      click_button "Import"

      expect(page).to have_selector("[data-testid='import-summary']", text: "1 row imported, 0 rows failed.")

      post = BlogPost.find_by!(title: "My Zip Post")
      expect(post.user).to eq(owner)
      expect(post.body).to include("data:image/png;base64,")
      expect(post.published?).to be false
      expect(post.classification).to eq("restricted")
      expect(post.blog_category).to eq(category)
    end

    # Turbo Drive's fetch-based form submission doesn't reliably carry a
    # multipart file upload — Occasions' own Import page already worked
    # around this with `data: { turbo: false }` on its form. rack_test (the
    # driver every other example here uses) never exercises Turbo at all, so
    # only a real js: true example actually catches this class of bug —
    # confirmed by manual testing that clicking Import silently did nothing
    # before the form picked up the same `data: { turbo: false }` fix.
    it "Submits the form and shows results with JavaScript enabled", js: true do
      category = create(:blog_category, name: "Technology")
      file = csv_file_for([ [ "My JS Imported Post", "Technology", "", "", "Some body text." ] ])

      sign_in_as(owner)
      # Settle on the post-sign-in page before navigating — in a real browser
      # the `visit` below can otherwise race sign_in_as's redirect and land
      # back on the sign-in form (no file field).
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']")
      visit new_blog_import_path
      attach_file("file", file.path)
      click_button "Import"

      expect(page).to have_selector("[data-testid='import-summary']", text: "1 row imported, 0 rows failed.")
      expect(BlogPost.find_by(title: "My JS Imported Post")).to be_present
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

      expect(page).to have_content("Please choose a file to import.")
    end

    it "Shows an alert when the uploaded file is neither CSV nor ZIP" do
      sign_in_as(owner)
      visit new_blog_import_path
      attach_file("file", Rails.root.join("spec/fixtures/files/test_image.jpg"))
      click_button "Import"

      expect(page).to have_content("The uploaded file must be a CSV or ZIP file.")
    end

    it "Shows a failed import when the ZIP has no Markdown file" do
      create(:blog_category, name: "Technology")
      file = zip_file_for("readme.txt" => "hello")

      sign_in_as(owner)
      # Settle on the post-sign-in page before navigating — in a real browser
      # the `visit` below can otherwise race sign_in_as's redirect and land
      # back on the sign-in form (no file field).
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']")
      visit new_blog_import_path
      attach_file("file", file.path)
      find("[data-testid='import-category-select']").select("Technology")
      click_button "Import"

      expect(page).to have_selector("[data-testid='import-summary']", text: "0 rows imported, 1 row failed.")
      expect(page).to have_selector("[data-testid='import-error-row']", text: /exactly one Markdown/)
    end

    it "Shows an alert when a ZIP is uploaded without choosing a Category" do
      file = zip_file_for("My_Zip_Post.md" => "Text")

      sign_in_as(owner)
      # Settle on the post-sign-in page before navigating — in a real browser
      # the `visit` below can otherwise race sign_in_as's redirect and land
      # back on the sign-in form (no file field).
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']")
      visit new_blog_import_path
      attach_file("file", file.path)
      click_button "Import"

      expect(page).to have_content("Please choose a Category for a ZIP import.")
      expect(BlogPost.find_by(title: "My Zip Post")).to be_nil
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows failed rows with their error messages alongside successful ones" do
      create(:blog_category, name: "Technology")
      file = csv_file_for([
        [ "", "Technology", "", "", "Body" ],
        [ "Good Post", "Technology", "", "", "Body" ]
      ])

      sign_in_as(owner)
      # Settle on the post-sign-in page before navigating — in a real browser
      # the `visit` below can otherwise race sign_in_as's redirect and land
      # back on the sign-in form (no file field).
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']")
      visit new_blog_import_path
      attach_file("file", file.path)
      click_button "Import"

      expect(page).to have_selector("[data-testid='import-summary']", text: "1 row imported, 1 row failed.")
      expect(page).to have_selector("[data-testid='import-error-row']", text: "2")
    end

    it "Ignores the Category select for a CSV upload, using each row's own Category" do
      create(:blog_category, name: "Technology")
      create(:blog_category, name: "Travel")
      file = csv_file_for([ [ "My Post", "Technology", "", "", "Body" ] ])

      sign_in_as(owner)
      # Settle on the post-sign-in page before navigating — in a real browser
      # the `visit` below can otherwise race sign_in_as's redirect and land
      # back on the sign-in form (no file field).
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']")
      visit new_blog_import_path
      attach_file("file", file.path)
      find("[data-testid='import-category-select']").select("Travel")
      click_button "Import"

      expect(page).to have_selector("[data-testid='import-summary']", text: "1 row imported, 0 rows failed.")
      expect(BlogPost.find_by!(title: "My Post").blog_category.name).to eq("Technology")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Fails a CSV row whose Category doesn't match any existing one" do
      file = csv_file_for([ [ "My Post", "No Such Category", "", "", "Body" ] ])

      sign_in_as(owner)
      # Settle on the post-sign-in page before navigating — in a real browser
      # the `visit` below can otherwise race sign_in_as's redirect and land
      # back on the sign-in form (no file field).
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']")
      visit new_blog_import_path
      attach_file("file", file.path)
      click_button "Import"

      expect(page).to have_selector("[data-testid='import-summary']", text: "0 rows imported, 1 row failed.")
      expect(page).to have_selector("[data-testid='import-error-row']", text: "Category 'No Such Category' not found")
      expect(BlogPost.find_by(title: "My Post")).to be_nil
    end
  end
end
