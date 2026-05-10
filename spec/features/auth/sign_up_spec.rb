# spec/features/auth/sign_up_spec.rb
require "rails_helper"

RSpec.describe "Sign Up", type: :feature do
  describe "Happy path" do
    it "Renders the info panel" do
      visit sign_up_path
      expect(page).to have_selector("[data-testid='sign-up-info']")
    end

    it "Renders the first name field" do
      visit sign_up_path
      expect(page).to have_field("First name")
    end

    it "Renders the last name field" do
      visit sign_up_path
      expect(page).to have_field("Last name")
    end

    it "Renders the profile image field" do
      visit sign_up_path
      expect(page).to have_selector("[data-testid='sign-up-profile-image']")
    end

    it "Renders the email address field" do
      visit sign_up_path
      expect(page).to have_field("Email address")
    end

    it "Renders the password field" do
      visit sign_up_path
      expect(page).to have_field("Password")
    end

    it "Renders the password confirmation field" do
      visit sign_up_path
      expect(page).to have_field("Password confirmation")
    end

    it "Renders the message to admin field" do
      visit sign_up_path
      expect(page).to have_field("Message to admin")
    end

    it "Renders the 'Cancel' button" do
      visit sign_up_path
      expect(page).to have_link("Cancel", href: root_path)
    end

    it "Renders the 'Sign Up' button" do
      visit sign_up_path
      expect(page).to have_button("Sign Up")
    end

    it "Submits a valid request and redirects to root without signing in" do
      visit sign_up_path

      attach_file "profile-image-input", Rails.root.join("spec/fixtures/files/test_image.jpg")
      fill_in "First name",    with: "Gary"
      fill_in "Last name",     with: "Guest"
      fill_in "Email address", with: "Gary.Guest@example.com"
      fill_in "Password",              with: "password123"
      fill_in "Password confirmation", with: "password123"
      click_button "Sign Up"

      expect(page).to have_current_path(root_path)
      expect(page).to have_selector("[data-testid='flash-notice']")
      expect(page).not_to have_selector("[data-testid='user-thumbnail-button']")
    end

    it "Creates the user with a pending status" do
      visit sign_up_path

      attach_file "profile-image-input", Rails.root.join("spec/fixtures/files/test_image.jpg")
      fill_in "First name",    with: "Gary"
      fill_in "Last name",     with: "Guest"
      fill_in "Email address", with: "Gary.Guest@example.com"
      fill_in "Password",              with: "password123"
      fill_in "Password confirmation", with: "password123"
      click_button "Sign Up"

      expect(User.last.status).to eq("pending")
    end
  end

  describe "Negative path" do
    it "Shows an error when first name is blank" do
      visit sign_up_path

      attach_file "profile-image-input", Rails.root.join("spec/fixtures/files/test_image.jpg")
      fill_in "First name",            with: ""
      fill_in "Last name",             with: "Guest"
      fill_in "Email address",         with: "Gary.Guest@example.com"
      fill_in "Password",              with: "password123"
      fill_in "Password confirmation", with: "password123"
      click_button "Sign Up"

      expect(page).to have_current_path(sign_up_path)
      expect(page).to have_selector("[data-testid='sign-up-errors']")
    end

    it "Shows an error when last name is blank" do
      visit sign_up_path

      attach_file "profile-image-input", Rails.root.join("spec/fixtures/files/test_image.jpg")
      fill_in "First name",            with: "Gary"
      fill_in "Last name",             with: ""
      fill_in "Email address",         with: "Gary.Guest@example.com"
      fill_in "Password",              with: "password123"
      fill_in "Password confirmation", with: "password123"
      click_button "Sign Up"

      expect(page).to have_current_path(sign_up_path)
      expect(page).to have_selector("[data-testid='sign-up-errors']")
    end

    it "Shows an error when profile image is missing" do
      visit sign_up_path

      fill_in "First name",            with: "Gary"
      fill_in "Last name",             with: "Guest"
      fill_in "Email address",         with: "Gary.Guest@example.com"
      fill_in "Password",              with: "password123"
      fill_in "Password confirmation", with: "password123"
      click_button "Sign Up"

      expect(page).to have_current_path(sign_up_path)
      expect(page).to have_selector("[data-testid='sign-up-errors']")
    end

    it "Shows an error when email address is blank" do
      visit sign_up_path

      attach_file "profile-image-input", Rails.root.join("spec/fixtures/files/test_image.jpg")
      fill_in "First name",            with: "Gary"
      fill_in "Last name",             with: "Guest"
      fill_in "Email address",         with: ""
      fill_in "Password",              with: "password123"
      fill_in "Password confirmation", with: "password123"
      click_button "Sign Up"

      expect(page).to have_current_path(sign_up_path)
      expect(page).to have_selector("[data-testid='sign-up-errors']")
    end

    it "Shows an error when email address is already taken" do
      create(:user, email_address: "Gary.Guest@example.com")

      visit sign_up_path

      attach_file "profile-image-input", Rails.root.join("spec/fixtures/files/test_image.jpg")
      fill_in "First name",            with: "Gary"
      fill_in "Last name",             with: "Guest"
      fill_in "Email address",         with: "Gary.Guest@example.com"
      fill_in "Password",              with: "password123"
      fill_in "Password confirmation", with: "password123"
      click_button "Sign Up"

      expect(page).to have_current_path(sign_up_path)
      expect(page).to have_selector("[data-testid='sign-up-errors']")
    end

    it "Shows an error when password is blank" do
      visit sign_up_path

      attach_file "profile-image-input", Rails.root.join("spec/fixtures/files/test_image.jpg")
      fill_in "First name",            with: "Gary"
      fill_in "Last name",             with: "Guest"
      fill_in "Email address",         with: "Gary.Guest@example.com"
      fill_in "Password",              with: ""
      fill_in "Password confirmation", with: ""
      click_button "Sign Up"

      expect(page).to have_current_path(sign_up_path)
      expect(page).to have_selector("[data-testid='sign-up-errors']")
    end

    it "Shows an error when password confirmation does not match" do
      visit sign_up_path

      attach_file "profile-image-input", Rails.root.join("spec/fixtures/files/test_image.jpg")
      fill_in "First name",            with: "Gary"
      fill_in "Last name",             with: "Guest"
      fill_in "Email address",         with: "Gary.Guest@example.com"
      fill_in "Password",              with: "password123"
      fill_in "Password confirmation", with: "different"
      click_button "Sign Up"

      expect(page).to have_current_path(sign_up_path)
      expect(page).to have_selector("[data-testid='sign-up-errors']")
    end
  end

  describe "Alternative path" do
    it "Creates an account with an email address in mixed case" do
      visit sign_up_path

      attach_file "profile-image-input", Rails.root.join("spec/fixtures/files/test_image.jpg")
      fill_in "First name",            with: "Gary"
      fill_in "Last name",             with: "Guest"
      fill_in "Email address",         with: "GARY.GUEST@EXAMPLE.COM"
      fill_in "Password",              with: "password123"
      fill_in "Password confirmation", with: "password123"
      click_button "Sign Up"

      expect(page).to have_current_path(root_path)
    end

    it "Submits a valid request with an optional message to admin" do
      visit sign_up_path

      attach_file "profile-image-input", Rails.root.join("spec/fixtures/files/test_image.jpg")
      fill_in "First name",            with: "Gary"
      fill_in "Last name",             with: "Guest"
      fill_in "Email address",         with: "Gary.Guest@example.com"
      fill_in "Password",              with: "password123"
      fill_in "Password confirmation", with: "password123"
      fill_in "Message to admin",      with: "Hi, I'm James's friend from work."
      click_button "Sign Up"

      expect(page).to have_current_path(root_path)
      expect(User.last.message_to_admin).to eq("Hi, I'm James's friend from work.")
    end
  end

  describe "Edge cases" do
    it "Is accessible to an unauthenticated visitor" do
      visit sign_up_path
      expect(page).to have_current_path(sign_up_path)
    end
  end
end
