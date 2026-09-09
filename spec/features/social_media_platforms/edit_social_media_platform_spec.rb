# spec/features/social_media_platforms/edit_social_media_platform_spec.rb

require "rails_helper"

RSpec.describe "Edit Social Media Platform", type: :feature do
  let(:admin)    { create(:user, :admin) }
  let!(:platform) { create(:social_media_platform, name: "Facebook", url: "https://www.facebook.com/", description: "Social networking.") }

  before { sign_in_as(admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Updates the name and regenerates the slug" do
      p = create(:social_media_platform, name: "Insta", url: "https://www.instagram.com/", description: "Photos.")
      visit edit_social_media_platform_path(p)
      fill_in "Name", with: "Instagram"
      click_button "Update Social Media Platform"
      p.reload
      expect(page).to have_current_path(social_media_platform_path(p))
      expect(page).to have_selector("h1.page-title", text: "Instagram")
      expect(p.slug).to eq("instagram")
    end

    it "Updates the url" do
      p = create(:social_media_platform, name: "Strava", url: "https://www.strava.com/", description: "Fitness.")
      visit edit_social_media_platform_path(p)
      fill_in "URL", with: "https://strava.com/"
      click_button "Update Social Media Platform"
      p.reload
      expect(p.url).to eq("https://strava.com/")
    end

    it "Shows the edit form heading with the platform name" do
      visit edit_social_media_platform_path(platform)
      expect(page).to have_selector("h1.page-title", text: "Facebook")
    end

    it "Pre-populates the name field" do
      visit edit_social_media_platform_path(platform)
      expect(page).to have_field("Name", with: "Facebook")
    end

    it "Pre-populates the url field" do
      visit edit_social_media_platform_path(platform)
      expect(page).to have_field("URL", with: "https://www.facebook.com/")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error when updated name is already taken" do
      create(:social_media_platform, name: "Instagram", url: "https://www.instagram.com/")
      p = create(:social_media_platform, name: "Strava", url: "https://www.strava.com/")
      visit edit_social_media_platform_path(p)
      fill_in "Name", with: "Instagram"
      click_button "Update Social Media Platform"
      expect(page).to have_content("has already been taken")
      p.reload
      expect(p.name).to eq("Strava")
    end

    it "Shows an error when url is not valid" do
      p = create(:social_media_platform, name: "Strava", url: "https://www.strava.com/")
      visit edit_social_media_platform_path(p)
      fill_in "URL", with: "not-a-url"
      click_button "Update Social Media Platform"
      expect(page).to have_content("must be a valid http(s) URL")
      p.reload
      expect(p.url).to eq("https://www.strava.com/")
    end

    it "Redirects 'Charlie Content Creator' to the social media platforms index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit edit_social_media_platform_path(platform)
      expect(page).to have_current_path(social_media_platforms_path)
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      click_button "Sign Out"
      visit edit_social_media_platform_path(platform)
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Old slug resolves to the record after a name change" do
      p = create(:social_media_platform, name: "Insta", url: "https://www.instagram.com/")
      old_slug = p.slug
      visit edit_social_media_platform_path(p)
      fill_in "Name", with: "Instagram"
      click_button "Update Social Media Platform"
      visit social_media_platform_path(old_slug)
      expect(page).to have_selector("h1.page-title", text: "Instagram")
    end

    it "Re-renders the form with entered values when validation fails" do
      p = create(:social_media_platform, name: "Strava", url: "https://www.strava.com/")
      visit edit_social_media_platform_path(p)
      fill_in "Name", with: ""
      click_button "Update Social Media Platform"
      expect(page).to have_field("URL", with: "https://www.strava.com/")
    end

    it "Allows 'Sam SysAdmin' to edit a social media platform" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit edit_social_media_platform_path(platform)
      fill_in "Name", with: "Meta / Facebook"
      click_button "Update Social Media Platform"
      expect(page).to have_selector("h1.page-title", text: "Meta / Facebook")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Preserves the description when only the name is changed" do
      visit edit_social_media_platform_path(platform)
      fill_in "Name", with: "Meta"
      click_button "Update Social Media Platform"
      expect(page).to have_selector("[data-testid='social-media-platform-description']",
                               text: "Social networking.")
    end

    it "Replaces an existing logo when a new one is uploaded" do
      platform.logo.attach(
        io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
        filename:     "test_image.jpg",
        content_type: "image/jpeg"
      )
      visit edit_social_media_platform_path(platform)
      attach_file "Logo", Rails.root.join("spec/fixtures/files/test_image.png")
      click_button "Update Social Media Platform"
      platform.reload
      expect(platform.logo.filename.to_s).to eq("test_image.png")
    end
  end
end
