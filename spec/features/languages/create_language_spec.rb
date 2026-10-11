# spec/features/languages/create_language_spec.rb

require "rails_helper"

RSpec.describe "Create Language", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in_as(admin) }

  def fill_language(name: "Swedish", code: "sv", flag: "🇸🇪")
    fill_in "Name", with: name
    fill_in "Code", with: code
    fill_in "Flag", with: flag
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates a language and shows it with a toast" do
      visit new_language_path
      fill_language
      click_button "Create Language"

      expect(page).to have_selector("h1.page-title", text: "Swedish")
      expect(page).to have_css("[data-testid='flash-success']", text: "Swedish has been successfully created")
      expect(Language.find_by!(name: "Swedish").code).to eq("sv")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error when the code is not two letters" do
      visit new_language_path
      fill_language(code: "swe")
      click_button "Create Language"

      expect(page).to have_content("must be two letters, e.g. sv")
      expect(Language.count).to eq(0)
    end

    it "Shows an error when the code is already used" do
      create(:language, name: "Svenska", code: "sv")
      visit new_language_path
      fill_language
      click_button "Create Language"

      expect(page).to have_content("has already been taken")
    end

    it "Shows an error when the flag is not an emoji" do
      visit new_language_path
      fill_language(flag: "SE")
      click_button "Create Language"

      expect(page).to have_content("must be a single emoji")
    end

    it "Redirects 'Charlie Content Creator' to the languages index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit new_language_path
      expect(page).to have_current_path(languages_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Re-renders the form with entered values when validation fails" do
      visit new_language_path
      fill_language(code: "swe")
      click_button "Create Language"

      expect(page).to have_field("Name", with: "Swedish")
      expect(page).to have_field("Code", with: "swe")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Stores an upper-case code with surrounding spaces as lower case" do
      visit new_language_path
      fill_language(code: " SV ")
      click_button "Create Language"

      expect(Language.find_by!(name: "Swedish").code).to eq("sv")
    end
  end
end
