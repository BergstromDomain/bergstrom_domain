# spec/features/recipes/filter_recipes_spec.rb

require "rails_helper"

RSpec.describe "Filter Recipes", type: :feature do
  let(:chef)     { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }
  let(:other)    { create(:user, :content_creator, first_name: "Grace", last_name: "Hopper") }
  let!(:italian) { create(:cuisine, name: "Italian", flag: "🇮🇹") }
  let!(:swedish) { create(:cuisine, name: "Swedish", flag: "🇸🇪") }
  let!(:pasta)   { create(:food_type, name: "Pasta", icon: "cooking-pot") }
  let!(:soup)    { create(:food_type, name: "Soup", icon: "soup") }
  let!(:english) { create(:language, name: "English", code: "en", flag: "🇬🇧") }
  let!(:svenska) { create(:language, name: "Swedish", code: "sv", flag: "🇸🇪") }

  def ingredients(*names)
    { "0" => { ingredients_attributes: names.each_with_index.to_h { |name, i| [ i.to_s, { quantity: "1", name: name } ] } } }
  end

  let!(:lasagna) do
    create(:recipe, :published, :unrestricted, user: chef, title: "Swedish Lasagna",
      cuisines: [ swedish, italian ], food_types: [ pasta ], language: svenska,
      ingredient_sections_attributes: ingredients("Minced beef", "Garlic", "Cream"))
  end
  let!(:pea_soup) do
    create(:recipe, :published, :unrestricted, user: other, title: "Pea Soup",
      cuisines: [ swedish ], food_types: [ soup ], language: english,
      ingredient_sections_attributes: ingredients("Yellow peas", "Onion"))
  end

  def titles
    all("[data-testid='filter-recipe-title']").map(&:text)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Narrows results with a Basic dropdown, matching a recipe's second Cuisine" do
      visit filter_recipes_path
      select "Italian", from: "cuisine_id"
      click_button "Apply Filters"

      expect(titles).to eq([ "Swedish Lasagna" ])
    end

    it "Combines Basic filters with AND" do
      visit filter_recipes_path(cuisine_id: swedish.slug, language_id: english.slug)
      expect(titles).to eq([ "Pea Soup" ])
    end

    it "Filters by ingredients with a SQL query" do
      visit filter_recipes_path(mode: "sql", query: 'ingredients CONTAINS "garlic" AND ingredients CONTAINS "cream"')
      expect(titles).to eq([ "Swedish Lasagna" ])
    end

    it "Sorts by a column and reverses on a second click" do
      visit filter_recipes_path
      click_link "Title"
      expect(titles).to eq([ "Pea Soup", "Swedish Lasagna" ])
      click_link "Title"
      expect(titles).to eq([ "Swedish Lasagna", "Pea Soup" ])
    end

    it "Displays the columns for each row" do
      visit filter_recipes_path(cuisine_id: italian.slug)

      expect(all("[data-testid='filter-results-table'] th").map(&:text))
        .to eq([ "Cuisine", "Food Type", "Title", "Chef", "Created ▼", "Published", "Reactions" ])
      within("[data-testid='filter-recipe-row']") do
        expect(page).to have_selector("[data-testid='filter-recipe-cuisine']", text: "Swedish · Italian")
        expect(page).to have_selector("[data-testid='filter-recipe-food-type']", text: "Pasta")
        expect(page).to have_selector("[data-testid='filter-recipe-chef']", text: "Ada Lovelace")
        expect(page).to have_selector("[data-testid='filter-recipe-published'] svg")
        expect(page).to have_selector("[data-testid='filter-recipe-reactions']", text: "No reactions yet")
      end
    end

    it "Opens a recipe with Back returning to the filtered list" do
      visit filter_recipes_path(cuisine_id: italian.slug)
      click_link "Swedish Lasagna"
      click_link "Back"
      expect(page).to have_current_path(filter_recipes_path(cuisine_id: italian.slug))
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows a friendly error and no results for a malformed SQL query" do
      visit filter_recipes_path(mode: "sql", query: "cuisine = ")

      expect(page).to have_selector("[data-testid='filter-error']")
      expect(page).not_to have_selector("[data-testid='filter-recipe-row']")
    end

    it "Never shows a restricted recipe to 'Gary Guest', even with a permissive SQL filter" do
      create(:recipe, :published, :restricted, user: chef, title: "Secret Sauce")
      visit filter_recipes_path(mode: "sql", query: "comments >= 0")

      expect(page).not_to have_content("Secret Sauce")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lists 'My Published Recipes' and 'My Draft Recipes' from the left nav" do
      create(:recipe, user: chef, title: "Work In Progress")
      sign_in_as(chef)

      visit cookbook_path
      within("[data-testid='left-nav']") { click_link "My Published Recipes" }
      expect(titles).to eq([ "Swedish Lasagna" ])

      within("[data-testid='left-nav']") { click_link "My Draft Recipes" }
      expect(titles).to eq([ "Work In Progress" ])
    end

    it "Toggles between Basic and SQL panels via the tab without a page reload", js: true do
      visit filter_recipes_path

      expect(page).to have_selector("[data-testid='sql-panel']", visible: :hidden)
      js_click("sql-tab")
      expect(page).to have_selector("[data-testid='sql-panel']", visible: true)
      expect(page).to have_selector("[data-testid='basic-panel']", visible: :hidden)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Offers only Cuisines and Languages that visible recipes use" do
      create(:cuisine, name: "French")
      visit filter_recipes_path

      expect(page).to have_select("cuisine_id", options: [ "All Cuisines", "Italian", "Swedish" ])
      expect(page).to have_select("language_id", options: [ "All Languages", "English", "Swedish" ])
    end

    it "Shows an empty message when nothing matches" do
      visit filter_recipes_path(mode: "sql", query: 'ingredients CONTAINS "saffron"')
      expect(page).to have_selector("[data-testid='empty-state']", text: "No recipes match this filter.")
    end
  end
end
