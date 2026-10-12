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
  # helper is available in every view, so the names can't be shared).
  def recipe_filter_sort_link(column)
    next_direction = (@sort == column && @direction == "asc") ? "desc" : "asc"
    query = request.query_parameters.merge("sort" => column, "direction" => next_direction)
    arrow = @sort == column ? (@direction == "asc" ? " ▲" : " ▼") : ""

    link_to "#{RECIPE_FILTER_SORT_LABELS.fetch(column)}#{arrow}", filter_recipes_path(query),
      data: { testid: "sort-#{column}" }
  end

  # A link into a recipe's Read page whose Back button returns to this page.
  def recipe_link_returning_here(recipe, **options)
    link_to recipe.title, recipe_path(recipe, return_to: request.fullpath), **options
  end

  # "Swedish · Italian" — a recipe's one or two Cuisines or Food Types.
  def recipe_choice_names(records)
    records.map(&:name).join(" · ")
  end
end
