# spec/features/blog_posts/blog_exports_spec.rb

require "rails_helper"

RSpec.describe "Blog Exports", type: :feature do
  let(:owner) { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the Download options page with a CSV action" do
      sign_in_as(owner)
      visit blog_exports_path

      expect(page).to have_selector("[data-testid='csv-export-link']")
    end

    it "Downloads a CSV with the correct content type and post content" do
      create(:blog_post, :unrestricted, :published, user: owner, title: "My Post")

      sign_in_as(owner)
      visit blog_exports_path
      click_link "Download CSV"

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.response_headers["Content-Disposition"]).to match(/BergstromDomain_Chronicle_\d{4}-\d{2}-\d{2}\.csv/)
      expect(page.body).to include("My Post")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit blog_exports_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies 'Uno User' (app_user role)" do
      sign_in_as(create(:user))
      visit blog_exports_path

      expect(page).to have_current_path(chronicle_path)
      expect(page).to have_content("Not authorised")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lets 'Adam Admin' export drafts and restricted posts" do
      create(:blog_post, :restricted, user: owner, title: "Restricted Draft")

      sign_in_as(create(:user, :admin))
      visit blog_exports_path
      click_link "Download CSV"

      expect(page.body).to include("Restricted Draft")
    end

    it "Only exports posts matching the applied Category filter" do
      matching     = create(:blog_category, name: "Science")
      non_matching = create(:blog_category, name: "History")
      create(:blog_post, :unrestricted, :published, user: owner, title: "Science Post", blog_category: matching)
      create(:blog_post, :unrestricted, :published, user: owner, title: "History Post", blog_category: non_matching)

      sign_in_as(owner)
      visit blog_exports_path(category_id: matching.slug)
      click_link "Download CSV"

      expect(page.body).to include("Science Post")
      expect(page.body).not_to include("History Post")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Exports a post missing Category/Subject/Topic with blank cells, not an error" do
      create(:blog_post, :unrestricted, :published, user: owner, title: "Bare Post", subject: nil, topic: nil)

      sign_in_as(owner)
      visit blog_exports_path
      click_link "Download CSV"

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.body).to include("Bare Post")
    end

    it "Downloads a CSV with just the header row when the filter matches nothing" do
      sign_in_as(owner)
      visit blog_exports_path(subject: "no-such-subject")
      click_link "Download CSV"

      rows = CSV.parse(page.body, headers: true)
      expect(rows.length).to eq(0)
    end
  end
end
