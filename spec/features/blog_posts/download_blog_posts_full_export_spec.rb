# spec/features/blog_posts/download_blog_posts_full_export_spec.rb

require "rails_helper"

RSpec.describe "Download Blog Posts Full Export (Admins)", type: :feature do
  let(:owner) { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }

  def zip_entry_names(body)
    names = []
    Zip::InputStream.open(StringIO.new(body)) do |io|
      while (entry = io.get_next_entry)
        names << entry.name
      end
    end
    names
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the Download Full Export action to an admin" do
      sign_in_as(create(:user, :admin))
      visit blog_exports_path

      expect(page).to have_selector("[data-testid='full-export-link']", text: "Download Full Export")
    end

    it "Downloads a zip with a csv/ folder and one images/<slug>/ folder per post" do
      post_a = create(:blog_post, :unrestricted, :published, user: owner, title: "First Post")
      post_a.blog_image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
        filename: "test_image.jpg", content_type: "image/jpeg"
      )

      sign_in_as(create(:user, :admin))
      visit blog_exports_path
      click_link "Download Full Export"

      expect(page.response_headers["Content-Type"]).to include("application/zip")
      expect(page.response_headers["Content-Disposition"]).to match(/BergstromDomain_Chronicle_FullExport_\d{4}-\d{2}-\d{2}\.zip/)
      names = zip_entry_names(page.body)
      expect(names).to include(a_string_starting_with("csv/"))
      expect(names).to include("images/#{post_a.slug}/blog_image.jpg")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit blog_exports_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Hides the Full Export action from a non-admin content creator" do
      sign_in_as(owner)
      visit blog_exports_path

      expect(page).to have_no_selector("[data-testid='full-export-link']")
    end

    it "Denies 'Charlie Content Creator' from downloading the full export directly" do
      sign_in_as(create(:user, :content_creator))
      visit full_blog_exports_path

      expect(page).to have_current_path(chronicle_path)
      expect(page).to have_content("Not authorised")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Only includes posts matching the applied Category filter, same as the other downloads" do
      matching     = create(:blog_category, name: "Science")
      non_matching = create(:blog_category, name: "History")
      create(:blog_post, :unrestricted, :published, user: owner, title: "Science Post", blog_category: matching)
      create(:blog_post, :unrestricted, :published, user: owner, title: "History Post", blog_category: non_matching)

      sign_in_as(create(:user, :admin))
      visit blog_exports_path(category_id: matching.slug)
      click_link "Download Full Export"

      rows = CSV.parse(zip_csv_body(page.body), headers: true)
      expect(rows.map { |r| r["Title"] }).to eq([ "Science Post" ])
    end

    it "Lets 'Sam SysAdmin' download the full export too" do
      create(:blog_post, :restricted, user: owner, title: "Restricted Draft")

      sign_in_as(create(:user, :system_admin))
      visit blog_exports_path
      click_link "Download Full Export"

      rows = CSV.parse(zip_csv_body(page.body), headers: true)
      expect(rows.map { |r| r["Title"] }).to eq([ "Restricted Draft" ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Downloads a zip with just the header row when the filter matches nothing" do
      sign_in_as(create(:user, :admin))
      visit blog_exports_path(subject: "no-such-subject")
      click_link "Download Full Export"

      rows = CSV.parse(zip_csv_body(page.body), headers: true)
      expect(rows.length).to eq(0)
    end
  end

  def zip_csv_body(zip_data)
    csv_content = nil
    Zip::InputStream.open(StringIO.new(zip_data)) do |io|
      while (entry = io.get_next_entry)
        csv_content = io.read if entry.name.start_with?("csv/")
      end
    end
    csv_content
  end
end
