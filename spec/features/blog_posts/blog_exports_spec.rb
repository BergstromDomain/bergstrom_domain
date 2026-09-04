# spec/features/blog_posts/blog_exports_spec.rb

require "rails_helper"

RSpec.describe "Download blog posts", type: :feature do
  let(:owner) { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Shows the Download options page with Print and CSV actions" do
      sign_in_as(owner)
      visit blog_exports_path

      expect(page).to have_selector("[data-testid='print-export-link']")
      expect(page).to have_selector("[data-testid='csv-export-link']")
    end

    it "Downloads a CSV with the correct content type and post content" do
      create(:blog_post, :unrestricted, :published, user: owner, title: "My Post")

      sign_in_as(owner)
      visit blog_exports_path
      click_link "Download CSV"

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.response_headers["Content-Disposition"]).to include("blog_posts_export_")
      expect(page.body).to include("My Post")
    end

    it "Shows a print-friendly listing with a print button hidden from the printed output" do
      create(:blog_post, :unrestricted, :published, user: owner, title: "Printable Post")

      sign_in_as(owner)
      visit blog_exports_path
      click_link "Print / Save as PDF"

      expect(page).to have_selector("[data-testid='print-post-row']", text: "Printable Post")
      expect(page).to have_selector(".print-hide [data-testid='print-button']")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
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

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Lets 'Adam Admin' export drafts and restricted posts" do
      create(:blog_post, :restricted, user: owner, title: "Restricted Draft")

      sign_in_as(create(:user, :admin))
      visit blog_exports_path
      click_link "Download CSV"

      expect(page.body).to include("Restricted Draft")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Exports a post missing Category/Subject/Topic with blank cells, not an error" do
      create(:blog_post, :unrestricted, :published, user: owner, title: "Bare Post", subject: nil, topic: nil)

      sign_in_as(owner)
      visit blog_exports_path
      click_link "Download CSV"

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.body).to include("Bare Post")
    end
  end
end
