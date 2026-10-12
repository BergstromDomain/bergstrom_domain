# app/controllers/recipe_exports_controller.rb

# Download Recipes (Block 11 in docs/context-prompts/active/Cookbook_App.md):
# Filter Recipes' Basic/SQL filter with CSV and PDF-ZIP downloads, the
# Recipe counterpart of BlogExportsController. Downloads keep the table's
# sort order. No Full Export until Import Recipes exists.
class RecipeExportsController < ApplicationController
  include Navigable
  include PdfDownloadable
  include RecipeFilterable

  before_action :require_can_export

  def index
    compute_filtered_recipes(includes: FILTER_RESULTS_INCLUDES)
    sort_filtered_recipes
  end

  def csv
    compute_filtered_recipes(includes: [ :cuisines, :food_types, :language, :user, { ingredient_sections: :ingredients } ])
    sort_filtered_recipes

    send_data RecipeExportService.new(@recipes).generate_csv,
              type:        "text/csv; charset=utf-8",
              filename:    "BergstromDomain_Cookbook_#{Date.current.iso8601}.csv",
              disposition: "attachment"
  end

  def pdfs
    compute_filtered_recipes(includes: [ :cuisines, :food_types, :language, :user, { ingredient_sections: :ingredients },
      { recipe_image_attachment: :blob } ])
    sort_filtered_recipes

    send_data ZipBundlingService.new(zip_entries_for(@recipes)).generate,
              type:        "application/zip",
              filename:    "BergstromDomain_Cookbook_#{Date.current.iso8601}.zip",
              disposition: "attachment"
  end

  private

  def require_can_export
    redirect_to cookbook_path, alert: "Not authorised." unless current_user&.can_export?
  end

  # Titles aren't unique, so a repeated "Title.pdf" gets a numeric suffix
  # rather than overwriting the earlier entry.
  def zip_entries_for(recipes)
    seen = Hash.new(0)
    recipes.each_with_object({}) do |recipe, entries|
      base = "#{recipe.title.gsub(' ', '_')}.pdf"
      seen[base] += 1
      filename = seen[base] == 1 ? base : base.sub(/\.pdf\z/, "_#{seen[base]}.pdf")
      entries[filename] = render_pdf(template: "recipes/pdf", assigns: { recipe: recipe })
    end
  end
end
