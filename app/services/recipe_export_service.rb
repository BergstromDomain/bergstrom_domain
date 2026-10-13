# app/services/recipe_export_service.rb
require "csv"

# Download Recipes' CSV (Block 11 in docs/context-prompts/archive/Cookbook_App.md):
# one row per recipe. Ingredients are one multi-line cell, each section's
# heading on its own line above its ingredients. The Method is stored as
# Markdown whichever editor wrote it, so it exports as-is.
class RecipeExportService
  HEADERS = [ "Title", "Cuisine", "Food Type", "Language", "Chef", "Created", "Published", "Serves",
              "Makes", "Cook Time", "Description", "Ingredients", "Method (Markdown)" ].freeze

  def initialize(recipes)
    @recipes = recipes
  end

  def generate_csv
    CSV.generate(headers: true, encoding: "UTF-8") do |csv|
      csv << HEADERS

      @recipes.each do |recipe|
        csv << [
          recipe.title,
          recipe.cuisines.map(&:name).join(" · "),
          recipe.food_types.map(&:name).join(" · "),
          recipe.language.name,
          "#{recipe.user.first_name} #{recipe.user.last_name}",
          recipe.created_at.strftime("%d-%b-%Y"),
          recipe.published? ? "Yes" : "No",
          recipe.serves,
          recipe.makes,
          recipe.cook_time,
          recipe.description,
          ingredient_lines(recipe).presence,
          recipe.body.presence
        ]
      end
    end
  end

  # "1 tbsp Butter, softened" — the same wording as the Read page and the PDF.
  def self.ingredient_line(ingredient)
    line = [ ingredient.quantity, ingredient.measurement, ingredient.name ].compact_blank.join(" ")
    ingredient.comment.present? ? "#{line}, #{ingredient.comment}" : line
  end

  private

  def ingredient_lines(recipe)
    recipe.ingredient_sections.flat_map do |section|
      [ section.heading.presence, *section.ingredients.map { |ingredient| self.class.ingredient_line(ingredient) } ].compact
    end.join("\n")
  end
end
