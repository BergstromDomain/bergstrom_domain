# spec/features/cuisines/list_cuisine_spec.rb

require "rails_helper"

RSpec.describe "List Cuisine", type: :feature do
  let!(:swedish) { create(:cuisine, name: "Swedish", flag: "🇸🇪", description: "Food from Sweden.") }
  let!(:french)  { create(:cuisine, name: "French",  flag: "🇫🇷", description: "Food from France.") }
  let!(:thai)    { create(:cuisine, name: "Thai",    flag: "🇹🇭", description: "Food from Thailand.") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit cuisines_path }

    it "Displays the page title" do
      expect(page).to have_selector("h1.page-title", text: "Cuisines")
    end

    it "Displays cuisines in alphabetical order by name" do
      expect(page.text.index("French")).to be < page.text.index("Swedish")
      expect(page.text.index("Swedish")).to be < page.text.index("Thai")
    end

    it "Shows each cuisine's flag with the Cuisine badge" do
      within(all("[data-testid='cuisine-row']").first) do
        expect(page).to have_selector("[data-testid='cuisine-flag'] .flag-badge__flag", text: "🇫🇷")
        expect(page).to have_selector("[data-testid='cuisine-flag'] .flag-badge__icon svg")
      end
    end

    it "Displays the description for each cuisine" do
      expect(page).to have_selector("td[data-testid='cuisine-description']", count: 3)
    end

    it "Links each cuisine name to its show page" do
      expect(page).to have_link("Swedish", href: cuisine_path(swedish))
      expect(page).to have_link("French",  href: cuisine_path(french))
    end

    it "Shows the Cookbook left nav" do
      within("[data-testid='left-nav']") do
        expect(page).to have_selector("[data-testid='left-nav-cookbook-h3']")
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Displays an empty state message when no cuisines exist" do
      Cuisine.delete_all
      visit cuisines_path
      expect(page).to have_selector("[data-testid='empty-state']")
      expect(page).not_to have_selector(".data-table")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Renders the same page for a signed-in 'Uno User'" do
      sign_in_as create(:user, :app_user)
      visit cuisines_path
      expect(page).to have_selector("h1.page-title", text: "Cuisines")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Sorts cuisines case-insensitively" do
      create(:cuisine, name: "argentinian", flag: "🇦🇷")
      visit cuisines_path
      expect(page.text.index("argentinian")).to be < page.text.index("French")
    end
  end
end
