# spec/features/blog_posts/download_blog_posts_pdfs_spec.rb

require "rails_helper"

RSpec.describe "Download Blog Posts as a zip of PDFs", type: :feature do
  let(:owner) { create(:user, :content_creator) }

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
    it "Shows the filter UI and a Download PDFs action on the Download Blog Posts page" do
      sign_in_as(owner)
      visit blog_exports_path

      expect(page).to have_selector("[data-testid='basic-panel']")
      expect(page).to have_selector("[data-testid='download-pdfs-link']", text: "Download PDFs")
    end

    it "Downloads a zip containing one PDF per visible post" do
      create(:blog_post, :unrestricted, :published, user: owner, title: "First Post")
      create(:blog_post, :unrestricted, :published, user: owner, title: "Second Post")

      sign_in_as(owner)
      visit blog_exports_path
      click_link "Download PDFs"

      expect(page.response_headers["Content-Type"]).to include("application/zip")
      expect(page.response_headers["Content-Disposition"]).to match(/BergstromDomain_Chronicle_\d{4}-\d{2}-\d{2}\.zip/)
      expect(zip_entry_names(page.body)).to contain_exactly("First_Post.pdf", "Second_Post.pdf")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit blog_exports_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies 'Uno User' (app_user role) from downloading PDFs directly" do
      sign_in_as(create(:user))
      visit pdfs_blog_exports_path

      expect(page).to have_current_path(chronicle_path)
      expect(page).to have_content("Not authorised")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Only zips posts matching the applied Category filter" do
      matching    = create(:blog_category, name: "Science")
      non_matching = create(:blog_category, name: "History")
      create(:blog_post, :unrestricted, :published, user: owner, title: "Science Post", blog_category: matching)
      create(:blog_post, :unrestricted, :published, user: owner, title: "History Post", blog_category: non_matching)

      sign_in_as(owner)
      visit blog_exports_path(category_id: matching.slug)
      click_link "Download PDFs"

      expect(zip_entry_names(page.body)).to contain_exactly("Science_Post.pdf")
    end

    it "Lets 'Adam Admin' download restricted/draft posts via the filter" do
      create(:blog_post, :restricted, user: owner, title: "Restricted Draft")

      sign_in_as(create(:user, :admin))
      visit blog_exports_path
      click_link "Download PDFs"

      expect(zip_entry_names(page.body)).to contain_exactly("Restricted_Draft.pdf")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Downloads a zip with no entries when the filter matches nothing" do
      sign_in_as(owner)
      visit blog_exports_path(subject: "no-such-subject")
      click_link "Download PDFs"

      expect(page.response_headers["Content-Type"]).to include("application/zip")
      expect(zip_entry_names(page.body)).to eq([])
    end

    it "De-duplicates a filename collision between two posts sharing the same title" do
      create(:blog_post, :unrestricted, :published, user: owner, title: "Same Title")
      create(:blog_post, :unrestricted, :published, user: create(:user, :content_creator), title: "Same Title")

      sign_in_as(create(:user, :admin))
      visit blog_exports_path
      click_link "Download PDFs"

      expect(zip_entry_names(page.body)).to contain_exactly("Same_Title.pdf", "Same_Title_2.pdf")
    end
  end
end
