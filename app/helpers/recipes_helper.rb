# app/helpers/recipes_helper.rb
module RecipesHelper
  RECIPE_FILTER_SORT_LABELS = {
    "cuisine"   => "Cuisine",
    "food_type" => "Food Type",
    "title"     => "Title",
    "chef"      => "Chef",
    "created"   => "Created",
    "reactions" => "Reactions"
  }.freeze

  # The Filter Recipes counterpart of BlogPostsHelper#filter_sort_link (every
  # helper is available in every view, so the names can't be shared). Links
  # back to the current page, so Download Recipes' table sorts too.
  def recipe_filter_sort_link(column)
    next_direction = (@sort == column && @direction == "asc") ? "desc" : "asc"
    query = request.query_parameters.merge("sort" => column, "direction" => next_direction)
    arrow = @sort == column ? (@direction == "asc" ? " ▲" : " ▼") : ""

    link_to "#{RECIPE_FILTER_SORT_LABELS.fetch(column)}#{arrow}", "#{request.path}?#{query.to_query}",
      data: { testid: "sort-#{column}" }
  end

  # A link into a recipe's Read page whose Back button returns to this page.
  def recipe_link_returning_here(recipe, **options)
    link_to recipe.title, recipe_path(recipe, return_to: request.fullpath), **options
  end

  # A recipe's Read page image, inlined for its PDF (no browsing context to
  # resolve a relative URL) — see BlogPostsHelper#blog_image_data_uri.
  def recipe_image_data_uri(recipe)
    return nil unless recipe.recipe_image.attached?

    blob = recipe.recipe_image.blob
    "data:#{blob.content_type};base64,#{Base64.strict_encode64(blob.download)}"
  end

  # "Swedish · Italian" — a recipe's one or two Cuisines or Food Types.
  def recipe_choice_names(records)
    records.map(&:name).join(" · ")
  end
end
