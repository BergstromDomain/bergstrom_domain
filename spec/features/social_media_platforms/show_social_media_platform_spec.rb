# spec/features/social_media_platforms/show_social_media_platform_spec.rb

require "rails_helper"

RSpec.describe "Show social media platform", type: :feature do
  let(:admin)           { create(:user, :admin) }
  let(:content_creator) { create(:user, :content_creator) }
  let!(:platform) do
    create(:social_media_platform,
      name:        "Facebook",
      url:         "https://www.facebook.com/",
      description: "Social networking and messaging platform.")
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    before { visit social_media_platform_path(platform) }

    it "Displays the platform name in the page title" do
      expect(page).to have_selector("h1.page-title", text: "Facebook")
    end

    it "Displays the platform description" do
      expect(page).to have_selector("[data-testid='social-media-platform-description']",
                               text: "Social networking and messaging platform.")
    end

    it "Shows a clickable link to the platform's URL" do
      expect(page).to have_link("https://www.facebook.com/", href: "https://www.facebook.com/")
    end

    it "Displays the platform name in the metadata panel" do
      expect(page).to have_selector("[data-testid='social-media-platform-name-value']", text: "Facebook")
    end

    it "Shows a back link to the index" do
      expect(page).to have_link("Back to Social Media Platforms", href: social_media_platforms_path)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Gary Guest'" do
      expect(page).not_to have_link("Edit Social Media Platform")
      expect(page).not_to have_button("Delete Social Media Platform")
    end

    it "Is accessible by slug" do
      visit social_media_platform_path(platform.slug)
      expect(page).to have_selector("h1.page-title", text: "Facebook")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Returns 404 for a non-existent slug" do
      visit social_media_platform_path("non-existent-slug")
      expect(page).to have_http_status(:not_found)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Charlie Content Creator'" do
      sign_in_as content_creator
      visit social_media_platform_path(platform)
      expect(page).not_to have_link("Edit Social Media Platform")
      expect(page).not_to have_button("Delete Social Media Platform")
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Uno User'" do
      sign_in_as create(:user, :app_user)
      visit social_media_platform_path(platform)
      expect(page).not_to have_link("Edit Social Media Platform")
      expect(page).not_to have_button("Delete Social Media Platform")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    context "As 'Adam Admin'" do
      before do
        sign_in_as admin
        visit social_media_platform_path(platform)
      end

      it "Shows the 'Edit' button" do
        expect(page).to have_link("Edit Social Media Platform",
                                  href: edit_social_media_platform_path(platform))
      end

      it "Shows the 'Delete' button" do
        expect(page).to have_button("Delete Social Media Platform")
      end

      it "Shows the button divider between the 'Back' and the 'Edit' buttons" do
        expect(page).to have_selector(".btn-divider")
      end
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Handles a platform with a long name without breaking layout" do
      long = create(:social_media_platform, name: "A" * 60, url: "https://example.com/", description: "Test.")
      visit social_media_platform_path(long)
      expect(page).to have_selector("h1.page-title")
    end

    it "Shows both the 'Edit' and the 'Delete' buttons to 'Sam SysAdmin'" do
      sign_in_as create(:user, :system_admin)
      visit social_media_platform_path(platform)
      expect(page).to have_link("Edit Social Media Platform")
      expect(page).to have_button("Delete Social Media Platform")
    end
  end
end
