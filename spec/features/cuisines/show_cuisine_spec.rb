# spec/features/cuisines/show_cuisine_spec.rb

require "rails_helper"

RSpec.describe "Show Cuisine", type: :feature do
  let!(:cuisine) { create(:cuisine, name: "Swedish", flag: "🇸🇪", description: "Food from Sweden.") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit cuisine_path(cuisine) }

    it "Displays the cuisine name in the page title" do
      expect(page).to have_selector("h1.page-title", text: "Swedish")
    end

    it "Shows the flag with the Cuisine badge in the main panel" do
      within("[data-testid='show-panel-main']") do
        expect(page).to have_selector(".flag-badge--large .flag-badge__flag", text: "🇸🇪")
        expect(page).to have_selector(".flag-badge__icon svg")
      end
    end

    it "Displays the description" do
      expect(page).to have_selector("[data-testid='cuisine-description']", text: "Food from Sweden.")
    end

    it "Displays the name in the metadata panel" do
      expect(page).to have_selector("[data-testid='cuisine-name-value']", text: "Swedish")
    end

    it "Shows a back link to the index" do
      expect(page).to have_link("Back", href: cuisines_path, exact: true)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Gary Guest'" do
      expect(page).not_to have_link("Edit Cuisine")
      expect(page).not_to have_button("Delete Cuisine")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Returns 404 for a non-existent slug" do
      visit cuisine_path("non-existent-slug")
      expect(page).to have_http_status(:not_found)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Charlie Content Creator'" do
      sign_in_as create(:user, :content_creator)
      visit cuisine_path(cuisine)
      expect(page).not_to have_link("Edit Cuisine")
      expect(page).not_to have_button("Delete Cuisine")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows the 'Edit' and the 'Delete' buttons to 'Adam Admin'" do
      sign_in_as create(:user, :admin)
      visit cuisine_path(cuisine)
      expect(page).to have_link("Edit Cuisine", href: edit_cuisine_path(cuisine))
      expect(page).to have_button("Delete Cuisine")
    end

    it "Is accessible by slug" do
      visit cuisine_path("swedish")
      expect(page).to have_selector("h1.page-title", text: "Swedish")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows a regional cuisine's non-flag emoji" do
      regional = create(:cuisine, name: "Mediterranean", flag: "🌍")
      visit cuisine_path(regional)
      expect(page).to have_selector(".flag-badge__flag", text: "🌍")
    end
  end
end
