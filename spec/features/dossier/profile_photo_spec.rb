# spec/features/dossier/profile_photo_spec.rb
require "rails_helper"

# A Dossier Profile photo, shown in the Profile header. Without one, the
# user's Settings picture stands in, and without that a person icon.
RSpec.describe "Dossier Profile photo", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:uno)     { create(:user) }
  let!(:profile) { create(:dossier_profile, user: charlie, display_name: "Charlie Content") }

  def photo = find("[data-testid='profile-photo']")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the photo Charlie uploads on Edit Profile in the Profile header" do
      sign_in_as(charlie)
      visit edit_dossier_profile_path
      attach_file "Photo", file_fixture("test_image.jpg")
      click_button "Save Profile"

      expect(page).to have_css("[data-testid='flash-success']")
      within(".page-header") { expect(photo[:src]).to include("test_image.jpg") }
      expect(photo[:alt]).to eq("Charlie Content")
      expect(profile.reload.photo).to be_attached
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Refuses a GIF, saving nothing" do
      sign_in_as(charlie)
      visit edit_dossier_profile_path
      attach_file "Photo", file_fixture("test_image.gif")
      click_button "Save Profile"

      expect(page).to have_selector("[data-testid='field-error']", text: "must be a JPEG, PNG or WebP")
      expect(profile.reload.photo).not_to be_attached
    end

    it "Keeps Uno and Gary away from Edit Profile" do
      sign_in_as(uno)
      visit edit_dossier_profile_path
      expect(page).to have_current_path(dossier_path)
      expect(page).to have_text("Not authorised.")

      Capybara.reset_session!
      visit edit_dossier_profile_path
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Falls back to Charlie's Settings picture without a Dossier photo" do
      charlie.profile_image.attach(file_fixture("test_image.png"))
      sign_in_as(charlie)
      visit dossier_profile_path

      expect(photo[:src]).to include("test_image.png")
    end

    it "Goes back to the Settings picture after Remove Photo" do
      charlie.profile_image.attach(file_fixture("test_image.png"))
      profile.photo.attach(file_fixture("test_image.jpg"))
      sign_in_as(charlie)
      visit edit_dossier_profile_path
      check "Remove Photo"
      click_button "Save Profile"

      expect(photo[:src]).to include("test_image.png")
      expect(profile.reload.photo).not_to be_attached
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows a person icon with neither picture, and no Remove Photo box" do
      sign_in_as(charlie)
      visit dossier_profile_path

      expect(page).to have_selector("[data-testid='profile-photo-placeholder']")
      expect(page).not_to have_selector("[data-testid='profile-photo']")
      visit edit_dossier_profile_path
      expect(page).not_to have_field("Remove Photo")
    end
  end
end
