# app/controllers/concerns/recipe_filterable.rb

# Basic/SQL filtering for "the recipes the current viewer can see, narrowed by
# the Filter Recipes params" — the Recipe counterpart of BlogPostFilterable,
# kept separate so Download Recipes (a later block) can reuse it.
module RecipeFilterable
  extend ActiveSupport::Concern

  private

  # `includes` is whatever the caller's own page renders (and sorts) per
  # recipe; anything else a query reads is preloaded via RecipeFilter.preload.
  def compute_filtered_recipes(includes: [])
    recipes = visible_recipes_scope.includes(*includes).to_a

    @mode  = params[:mode] == "sql" ? "sql" : "basic"
    @query = params[:query].to_s
    @filter_error = nil
    @recipes = recipes

    begin
      ast =
        if @mode == "sql"
          @query.presence && Jql::Parser.parse(@query)
        else
          RecipeFilter.basic_ast(**basic_filter_params)
        end

      if ast
        RecipeFilter::EVALUATOR.validate!(ast)
        RecipeFilter.preload(recipes, RecipeFilter::EVALUATOR.fields(ast))
        @recipes = recipes.select { |recipe| RecipeFilter::EVALUATOR.matches?(ast, RecipeFilter.attributes_for(recipe)) }
      end
    rescue Jql::ParseError => e
      @filter_error = e.message
      @recipes = []
    end

    set_filter_options(recipes)
  end

  # Mirrors BlogPostFilterable#visible_blog_posts_scope — Recipe has the same
  # three visibility scopes.
  def visible_recipes_scope
    if !authenticated?
      Recipe.visible_to_visitors
    elsif current_user.can_administer?
      Recipe.visible_to_admins
    else
      Recipe.visible_to_users(current_user)
    end
  end

  def basic_filter_params
    chef = params[:chef_id].presence && User.find_by(id: params[:chef_id])

    {
      cuisine:       safe_find(Cuisine, params[:cuisine_id])&.name,
      food_type:     safe_find(FoodType, params[:food_type_id])&.name,
      language:      safe_find(Language, params[:language_id])&.name,
      chef_name:     chef && "#{chef.first_name} #{chef.last_name}",
      created_range: created_range_for(params[:created]),
      published:     published_filter_for(params[:published])
    }
  end

  def safe_find(model, slug)
    slug.presence && model.friendly.find(slug)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def published_filter_for(value)
    case value
    when "published" then "true"
    when "draft"     then "false"
    end
  end

  def created_range_for(value)
    case value
    when "today"      then Date.current..Date.current
    when "this_week"  then Date.current.beginning_of_week..Date.current
    when "this_month" then Date.current.beginning_of_month..Date.current
    when "this_year"  then Date.current.beginning_of_year..Date.current
    end
  end

  # Only values the viewer's visible recipes actually use, like Chronicle's
  # Category dropdown — read from the join tables, so nothing per recipe.
  def set_filter_options(recipes)
    ids = recipes.map(&:id)
    @cuisine_options   = Cuisine.where(id: RecipeCuisine.where(recipe_id: ids).select(:cuisine_id)).order("LOWER(name) ASC")
    @food_type_options = FoodType.where(id: RecipeFoodType.where(recipe_id: ids).select(:food_type_id)).order("LOWER(name) ASC")
    @language_options  = Language.where(id: recipes.map(&:language_id).uniq).order("LOWER(name) ASC")
    @chef_options      = User.where(id: recipes.map(&:user_id).uniq)
      .sort_by { |user| [ user.last_name.downcase, user.first_name.downcase ] }
  end
end
