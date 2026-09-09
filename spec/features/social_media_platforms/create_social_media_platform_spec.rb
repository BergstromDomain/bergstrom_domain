# spec/features/social_media_platforms/create_social_media_platform_spec.rb

require "rails_helper"

RSpec.describe "Create social media platform", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in_as(admin) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Creates a social media platform with all required fields" do
      visit new_social_media_platform_path
      fill_in "Name",        with: "Facebook"
      fill_in "URL",         with: "https://www.facebook.com/"
      fill_in "Description", with: "Social networking platform."
      click_button "Create Social Media Platform"

      expect(page).to have_selector("h1.page-title", text: "Facebook")
    end

    it "Creates a social media platform with a logo image" do
      visit new_social_media_platform_path
      fill_in "Name", with: "Strava"
      fill_in "URL",  with: "https://www.strava.com/"
      attach_file "Logo", Rails.root.join("spec/fixtures/files/test_image.jpg")
      click_button "Create Social Media Platform"

      expect(page).to have_selector("h1.page-title", text: "Strava")
      expect(page).to have_selector("[data-testid='show-panel-main'] img")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Shows an error when name is missing" do
      visit new_social_media_platform_path
      fill_in "URL", with: "https://www.facebook.com/"
      click_button "Create Social Media Platform"

      expect(page).to have_selector("[data-testid='field-error']")
      expect(page).to have_content("can't be blank")
      expect(SocialMediaPlatform.count).to eq(0)
    end

    it "Shows an error when name is a duplicate (same case)" do
      create(:social_media_platform, name: "Facebook", url: "https://www.facebook.com/")
      visit new_social_media_platform_path
      fill_in "Name", with: "Facebook"
      fill_in "URL",  with: "https://www.fb.com/"
      click_button "Create Social Media Platform"

      expect(page).to have_content("has already been taken")
      expect(SocialMediaPlatform.count).to eq(1)
    end

    it "Shows an error when name is a duplicate (different case)" do
      create(:social_media_platform, name: "Facebook", url: "https://www.facebook.com/")
      visit new_social_media_platform_path
      fill_in "Name", with: "facebook"
      fill_in "URL",  with: "https://www.fb.com/"
      click_button "Create Social Media Platform"

      expect(page).to have_content("has already been taken")
      expect(SocialMediaPlatform.count).to eq(1)
    end

    it "Shows an error when url is missing" do
      visit new_social_media_platform_path
      fill_in "Name", with: "Facebook"
      click_button "Create Social Media Platform"

      expect(page).to have_selector("[data-testid='field-error']")
      expect(page).to have_content("can't be blank")
      expect(SocialMediaPlatform.count).to eq(0)
    end

    it "Shows an error when url has no valid scheme" do
      visit new_social_media_platform_path
      fill_in "Name", with: "Facebook"
      fill_in "URL",  with: "www.facebook.com"
      click_button "Create Social Media Platform"

      expect(page).to have_content("must be a valid http(s) URL")
      expect(SocialMediaPlatform.count).to eq(0)
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      click_button "Sign Out"
      visit new_social_media_platform_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Redirects 'Charlie Content Creator' to the social media platforms index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit new_social_media_platform_path
      expect(page).to have_current_path(social_media_platforms_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Re-renders the form with entered values when validation fails" do
      visit new_social_media_platform_path
      fill_in "Name", with: "Facebook"
      fill_in "URL",  with: "not-a-url"
      click_button "Create Social Media Platform"

      expect(page).to have_field("Name", with: "Facebook")
    end

    it "Allows 'Sam SysAdmin' to create a social media platform" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit new_social_media_platform_path
      fill_in "Name", with: "Instagram"
      fill_in "URL",  with: "https://www.instagram.com/"
      click_button "Create Social Media Platform"

      expect(page).to have_selector("h1.page-title", text: "Instagram")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Shows an error when a non-image file is attached as the logo" do
      visit new_social_media_platform_path
      fill_in "Name", with: "Facebook"
      fill_in "URL",  with: "https://www.facebook.com/"
      attach_file "Logo", Rails.root.join("spec/fixtures/files/test_image.gif")
      click_button "Create Social Media Platform"

      expect(page).to have_content("must be a JPEG, PNG, or WebP")
      expect(SocialMediaPlatform.count).to eq(0)
    end
  end
end
