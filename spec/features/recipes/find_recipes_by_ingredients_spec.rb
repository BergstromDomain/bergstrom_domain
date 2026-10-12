# spec/features/recipes/find_recipes_by_ingredients_spec.rb

require "rails_helper"

RSpec.describe "Find Recipes By Ingredients", type: :feature do
  let(:chef) { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }

  def recipe_with(title, *names, **options)
    ingredients = { "0" => { ingredients_attributes: names.each_with_index.to_h { |name, i| [ i.to_s, { quantity: "1", name: name } ] } } }
    create(:recipe, :published, :unrestricted, user: chef, title: title, ingredient_sections_attributes: ingredients, **options)
  end

  let!(:creamy_chicken) { recipe_with("Creamy Chicken", "Chicken breast", "Garlic cloves", "Double cream", created_at: 1.day.ago) }
  let!(:roast_chicken)  { recipe_with("Roast Chicken", "Whole chicken", "Garlic", created_at: 2.days.ago) }
  let!(:chicken_salad)  { recipe_with("Chicken Salad", "Chicken thigh", "Lettuce", created_at: 3.days.ago) }

  def titles
    all("[data-testid='browse-recipe-title']").map(&:text)
  end

  def tally
    all("[data-testid='ingredient-tally-step']").map(&:text)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the recipes containing every ingredient, newest first, with a running tally" do
      visit find_by_ingredients_recipes_path(ingredients: [ "Chicken", "Garlic" ])

      expect(page).to have_selector("h1", text: "Find Recipes By Ingredients")
      expect(tally).to eq([ "Chicken 3", "Garlic 2" ])
      expect(titles).to eq([ "Creamy Chicken", "Roast Chicken" ])
    end

    it "Shows each recipe's matching ingredients on its card" do
      visit find_by_ingredients_recipes_path(ingredients: [ "Chicken", "Garlic", "Cream" ])

      within("[data-testid='browse-recipe-card']") do
        expect(page).to have_selector("[data-testid='browse-recipe-matched']",
          text: "Matched: Chicken breast · Garlic cloves · Double cream")
      end
    end

    it "Drops the count as ingredients are added and restores it when one is removed", js: true do
      visit find_by_ingredients_recipes_path

      fill_in "Ingredient", with: "Chicken\n"
      expect(page).to have_selector("[data-testid='ingredient-chip']", text: "Chicken")
      expect(page).to have_selector("[data-testid='ingredient-tally-step']", text: "Chicken 3")

      fill_in "Ingredient", with: "Garlic,"
      expect(page).to have_selector("[data-testid='ingredient-tally-step']", text: "Garlic 2")

      fill_in "Ingredient", with: "Cream\n"
      expect(page).to have_selector("[data-testid='ingredient-tally-step']", text: "Cream 1")
      expect(page).to have_selector("[data-testid='browse-recipe-card']", count: 1)
      expect(page).to have_no_button("Find Recipes")

      js_click("ingredient-chip-remove-cream")
      expect(page).to have_no_selector("[data-testid='ingredient-chip']", text: "Cream")
      expect(page).to have_selector("[data-testid='browse-recipe-card']", count: 2)
      expect(page).to have_current_path(find_by_ingredients_recipes_path(ingredients: [ "Chicken", "Garlic" ]))
    end

    it "Opens a recipe with Back returning to the search" do
      visit find_by_ingredients_recipes_path(ingredients: [ "Lettuce" ])
      click_link "Chicken Salad"
      click_link "Back"

      expect(page).to have_current_path(find_by_ingredients_recipes_path(ingredients: [ "Lettuce" ]))
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Says so when no recipe contains every ingredient" do
      visit find_by_ingredients_recipes_path(ingredients: [ "Chicken", "Saffron" ])

      expect(tally).to eq([ "Chicken 3", "Saffron 0" ])
      expect(page).to have_selector("[data-testid='empty-state']", text: "No recipes contain all of these ingredients.")
    end

    it "Never shows a restricted recipe to 'Gary Guest'" do
      create(:recipe, :published, :restricted, user: chef, title: "Secret Chicken",
        ingredient_sections_attributes: { "0" => { ingredients_attributes: { "0" => { quantity: "1", name: "Chicken" } } } })
      visit find_by_ingredients_recipes_path(ingredients: [ "Chicken" ])

      expect(tally).to eq([ "Chicken 3" ])
      expect(page).not_to have_content("Secret Chicken")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Searches comma-separated ingredients with the Find Recipes button when JavaScript is off" do
      visit find_by_ingredients_recipes_path
      fill_in "Ingredient", with: "chicken, lettuce"
      click_button "Find Recipes"

      expect(page).to have_selector("[data-testid='ingredient-chip']", count: 2)
      expect(tally).to eq([ "chicken 3", "lettuce 1" ])
      expect(titles).to eq([ "Chicken Salad" ])
    end

    it "Shows the owner their own draft" do
      create(:recipe, user: chef, title: "Draft Chicken",
        ingredient_sections_attributes: { "0" => { ingredients_attributes: { "0" => { quantity: "1", name: "Chicken" } } } })
      sign_in_as(chef)
      visit find_by_ingredients_recipes_path(ingredients: [ "Chicken" ])

      expect(titles).to include("Draft Chicken")
    end

    it "Opens from the left nav" do
      visit cookbook_path
      within("[data-testid='left-nav']") { click_link "Find Recipes By Ingredients" }

      expect(page).to have_current_path(find_by_ingredients_recipes_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows a hint and no recipes before any ingredient is entered" do
      visit find_by_ingredients_recipes_path

      expect(page).to have_selector("[data-testid='ingredient-search-hint']", text: "Add an ingredient to start.")
      expect(page).to have_no_selector("[data-testid='browse-recipe-card']")
      expect(page).to have_no_selector("[data-testid='ingredient-tally']")
    end

    it "Matches a plural against a singular ingredient name" do
      visit find_by_ingredients_recipes_path(ingredients: [ "Lettuces" ])
      expect(titles).to eq([ "Chicken Salad" ])
    end
  end
end
