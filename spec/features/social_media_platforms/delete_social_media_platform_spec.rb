# spec/features/social_media_platforms/delete_social_media_platform_spec.rb

require "rails_helper"

RSpec.describe "Delete Social Media Platform", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in_as(admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Deletes a social media platform with no associated accounts and redirects to index" do
      p = create(:social_media_platform, name: "Strava", url: "https://www.strava.com/")
      visit social_media_platform_path(p)
      click_button "Delete Social Media Platform"
      expect(page).to have_current_path(social_media_platforms_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Strava has been successfully deleted")
      expect(page).to have_no_css("[data-testid='social-media-platform-table']", text: "Strava")
    end

    it "Removes the social media platform from the database" do
      p = create(:social_media_platform, name: "Strava", url: "https://www.strava.com/")
      visit social_media_platform_path(p)
      expect {
        click_button "Delete Social Media Platform"
      }.to change(SocialMediaPlatform, :count).by(-1)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Does not delete a platform that has associated person accounts" do
      p = create(:social_media_platform, name: "Facebook", url: "https://www.facebook.com/")
      create(:person_social_media_account, social_media_platform: p)
      visit social_media_platform_path(p)
      expect {
        click_button "Delete Social Media Platform"
      }.not_to change(SocialMediaPlatform, :count)
    end

    it "Shows an error when deletion is prevented by associated person accounts" do
      p = create(:social_media_platform, name: "Facebook", url: "https://www.facebook.com/")
      create(:person_social_media_account, social_media_platform: p)
      visit social_media_platform_path(p)
      click_button "Delete Social Media Platform"
      expect(page).to have_content("Cannot delete record because dependent person social media accounts exist")
    end

    it "Does not show the 'Delete' button to 'Charlie Content Creator'" do
      p = create(:social_media_platform, name: "Facebook", url: "https://www.facebook.com/")
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit social_media_platform_path(p)
      expect(page).not_to have_button("Delete Social Media Platform")
    end

    it "Does not show the 'Delete' button to 'Gary Guest'" do
      p = create(:social_media_platform, name: "Facebook", url: "https://www.facebook.com/")
      click_button "Sign Out"
      visit social_media_platform_path(p)
      expect(page).not_to have_button("Delete Social Media Platform")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Allows 'Sam SysAdmin' to delete a social media platform" do
      p = create(:social_media_platform, name: "Strava", url: "https://www.strava.com/")
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit social_media_platform_path(p)
      click_button "Delete Social Media Platform"
      expect(page).to have_current_path(social_media_platforms_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows the 'Delete Social Media Platform' button to an 'Adam Admin'" do
      p = create(:social_media_platform, name: "Strava", url: "https://www.strava.com/")
      visit social_media_platform_path(p)
      expect(page).to have_button("Delete Social Media Platform")
    end
  end
end
