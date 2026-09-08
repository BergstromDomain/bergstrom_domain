# spec/features/social_media_platforms/list_social_media_platform_spec.rb

require "rails_helper"

RSpec.describe "List social media platforms", type: :feature do
  let!(:facebook)  { create(:social_media_platform, name: "Facebook",  url: "https://www.facebook.com/",  description: "Social networking.") }
  let!(:instagram) { create(:social_media_platform, name: "Instagram", url: "https://www.instagram.com/", description: "Photo sharing.") }
  let!(:strava)    { create(:social_media_platform, name: "Strava",    url: "https://www.strava.com/",    description: "Fitness tracking.") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    before { visit social_media_platforms_path }

    it "Displays the page title" do
      expect(page).to have_selector("h1.page-title", text: "Social Media Platforms")
    end

    it "Displays all social media platforms" do
      expect(page).to have_content("Facebook")
      expect(page).to have_content("Instagram")
      expect(page).to have_content("Strava")
    end

    it "Displays social media platforms in alphabetical order by name" do
      expect(page.text.index("Facebook")).to be < page.text.index("Instagram")
      expect(page.text.index("Instagram")).to be < page.text.index("Strava")
    end

    it "Displays the description for each platform" do
      expect(page).to have_selector("td[data-testid='social-media-platform-description']", count: 3)
    end

    it "Links each platform name to its show page" do
      expect(page).to have_link("Facebook",  href: social_media_platform_path(facebook))
      expect(page).to have_link("Instagram", href: social_media_platform_path(instagram))
    end

    it "Shows a clickable link to each platform's URL" do
      expect(page).to have_link("https://www.facebook.com/", href: "https://www.facebook.com/")
    end

    it "Shows a fallback icon in the logo cell when no logo is attached" do
      expect(page).to have_selector("td[data-testid='social-media-platform-logo'] svg", minimum: 3)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Displays an empty state message when no social media platforms exist" do
      SocialMediaPlatform.delete_all
      visit social_media_platforms_path
      expect(page).to have_http_status(:ok)
      expect(page).to have_selector("[data-testid='empty-state']")
      expect(page).not_to have_selector(".data-table")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Renders the same page regardless of authentication status" do
      sign_in_as create(:user, :app_user)
      visit social_media_platforms_path
      expect(page).to have_selector("h1.page-title", text: "Social Media Platforms")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Sorts social media platforms case-insensitively" do
      create(:social_media_platform, name: "acoustic vinyl trading", url: "https://example.com/vinyl", description: "Trading.")
      visit social_media_platforms_path
      expect(page.text.index("acoustic vinyl trading")).to be < page.text.index("Facebook")
    end
  end
end
