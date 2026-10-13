# spec/features/cuisines/create_cuisine_spec.rb

require "rails_helper"

RSpec.describe "Create Cuisine", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in_as(admin) }

  def fill_cuisine(name: "Swedish", flag: "🇸🇪", description: "Food from Sweden.")
    fill_in "Name",        with: name
    fill_in "Flag",        with: flag
    fill_in "Description", with: description
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates a cuisine and shows it with a toast" do
      visit new_cuisine_path
      fill_cuisine
      click_button "Create Cuisine"

      expect(page).to have_selector("h1.page-title", text: "Swedish")
      expect(page).to have_css("[data-testid='flash-success']", text: "Swedish has been successfully created")
      expect(Cuisine.find_by!(name: "Swedish").flag).to eq("🇸🇪")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error when the name is missing" do
      visit new_cuisine_path
      fill_cuisine(name: "")
      click_button "Create Cuisine"

      expect(page).to have_selector("[data-testid='field-error']", text: "can't be blank")
      expect(Cuisine.count).to eq(0)
    end

    it "Shows an error when the name is a duplicate in a different case" do
      create(:cuisine, name: "Swedish")
      visit new_cuisine_path
      fill_cuisine(name: "swedish")
      click_button "Create Cuisine"

      expect(page).to have_content("has already been taken")
      expect(Cuisine.count).to eq(1)
    end

    it "Shows an error when the flag is not an emoji" do
      visit new_cuisine_path
      fill_cuisine(flag: "SE")
      click_button "Create Cuisine"

      expect(page).to have_content("must be a single emoji")
      expect(Cuisine.count).to eq(0)
    end

    it "Shows an error when the description is missing" do
      visit new_cuisine_path
      fill_cuisine(description: "")
      click_button "Create Cuisine"

      expect(page).to have_selector("[data-testid='field-error']", text: "can't be blank")
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      click_button "Sign Out"
      visit new_cuisine_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Redirects 'Charlie Content Creator' to the cuisines index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit new_cuisine_path
      expect(page).to have_current_path(cuisines_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Re-renders the form with entered values when validation fails" do
      visit new_cuisine_path
      fill_cuisine(flag: "SE")
      click_button "Create Cuisine"

      expect(page).to have_field("Name", with: "Swedish")
      expect(page).to have_field("Flag", with: "SE")
    end

    it "Allows 'Sam SysAdmin' to create a cuisine" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit new_cuisine_path
      fill_cuisine(name: "Thai", flag: "🇹🇭")
      click_button "Create Cuisine"

      expect(page).to have_selector("h1.page-title", text: "Thai")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Rejects two emoji in the flag field" do
      visit new_cuisine_path
      fill_cuisine(flag: "🇸🇪🇫🇷")
      click_button "Create Cuisine"

      expect(page).to have_content("must be a single emoji")
    end
  end
end
