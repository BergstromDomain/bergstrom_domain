# app/controllers/recipes_controller.rb
class RecipesController < ApplicationController
  include Navigable
  include FormatConvertible
  include ReturnTo
  include Browsable
  include RecipeFilterable

  allow_unauthenticated_access only: %i[show browse_by_cuisine browse_by_food_type filter]
  before_action :resume_session_if_present, only: %i[show browse_by_cuisine browse_by_food_type filter]
  before_action :set_recipe,            only: %i[show edit update publish unpublish destroy restore]
  before_action :require_create_access, only: %i[new create convert_format]
  before_action :require_write_access,  only: %i[edit update publish unpublish]
  before_action :require_delete_access, only: %i[destroy]
  before_action :require_admin,         only: %i[deleted restore]

  # Two one-level BrowseTrees, one per reference-data list (Block 9 in
  # docs/context-prompts/active/Cookbook_App.md). A recipe counts under
  # each of its one or two Cuisines/Food Types.
  def browse_by_cuisine
    browse(title: "Browse Recipes By Cuisine", key: :cuisine_id, association: :cuisines,
      records: Cuisine, path_helper: :browse_by_cuisine_recipes_path)
  end

  def browse_by_food_type
    browse(title: "Browse Recipes By Food Type", key: :food_type_id, association: :food_types,
      records: FoodType, path_helper: :browse_by_food_type_recipes_path)
  end

  FILTER_SORT_COLUMNS = %w[cuisine food_type title chef created reactions].freeze

  def filter
    compute_filtered_recipes(includes: [ :likes, :cuisines, :food_types, { recipe_image_attachment: :blob },
      { user: { profile_image_attachment: :blob } } ])

    @sort      = FILTER_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "created"
    @direction = params[:direction] == "asc" ? "asc" : "desc"
    @recipes = RecipeFilter.sort(@recipes, @sort, @direction)
  end

  def new
    settings = current_user.app_settings_for("recipes")
    @recipe = current_user.recipes.build(
      classification: settings.default_classification,
      language:       settings.effective_default_language
    )
    @recipe.ingredient_sections.build.ingredients.build
  end

  def show
    @policy = Policy.new(current_user, @recipe)
    unless @policy.can_read?
      redirect_to cookbook_path, alert: "You do not have permission to view that recipe."
      return
    end
    @ingredient_sections = @recipe.ingredient_sections.includes(:ingredients)
  end

  def create
    @recipe = current_user.recipes.build(recipe_params)
    if @recipe.save
      toast_created(@recipe)
      redirect_to @recipe
    else
      build_blank_ingredient_list
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    build_blank_ingredient_list
  end

  # Unlike Chronicle, an edit leaves a published recipe published — see
  # "DECISIONS (Block 5)" in docs/context-prompts/active/Cookbook_App.md.
  def update
    previous_label = @recipe.to_toast_label
    if @recipe.update(recipe_params)
      toast_updated(@recipe, previous_label: previous_label)
      redirect_to @recipe
    else
      build_blank_ingredient_list
      render :edit, status: :unprocessable_entity
    end
  end

  def publish
    @recipe.published_at = Time.current
    if @recipe.save
      toast_published(@recipe)
    else
      toast_error(@recipe, prefix: "Cannot publish")
    end
    redirect_to @recipe
  end

  def unpublish
    @recipe.update!(published_at: nil)
    toast_unpublished(@recipe)
    redirect_to @recipe
  end

  # Soft delete: published or not, the recipe is hidden until an admin
  # restores it or PurgeDeletedRecipesJob removes it after 30 days. Written
  # without validations so a recipe that no longer meets today's publishing
  # rules can still be deleted and restored.
  def destroy
    @recipe.update_column(:deleted_at, Time.current)
    toast_deleted(@recipe, info: "The recipe can be restored by Admin for 30 days.")
    redirect_to cookbook_path
  end

  def deleted
    @recipes = Recipe.discarded.includes(:user).order(deleted_at: :desc)
  end

  # Comes back exactly as it was, published or draft.
  def restore
    @recipe.update_column(:deleted_at, nil)
    flash[:success] = "#{@recipe.to_toast_label} has been successfully restored"
    redirect_to deleted_recipes_path
  end

  private

  def browse(title:, key:, association:, records:, path_helper:)
    @browse_title = title
    level = BrowseTree::Level.new(key: key, association: association, records: records.order("LOWER(name) ASC"))
    return unless load_browse_tree(scope: visible_recipes_scope, levels: [ level ],
      root_label: "Cookbook", path_helper: path_helper)

    # Not with_attached_recipe_image: that also loads variant records, which
    # the card's thumbnail URL never reads.
    @browse_items = @browse_tree.items
      &.includes(:user, :language, :likes, :cuisines, :food_types, recipe_image_attachment: :blob)
    render :browse
  end

  def format_model = Recipe

  def set_recipe
    @recipe = Recipe.friendly.find(params[:id])
  end

  # The form always offers somewhere to start typing ingredients.
  def build_blank_ingredient_list
    @recipe.ingredient_sections.build.ingredients.build if @recipe.ingredient_sections.reject(&:marked_for_destruction?).empty?
  end

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end

  def require_create_access
    redirect_to cookbook_path, alert: "Not authorised." unless Policy.new(current_user, :recipes).can_create?
  end

  def require_delete_access
    @policy = Policy.new(current_user, @recipe)
    redirect_to @recipe, alert: "Not authorised." unless @policy.can_delete?
  end

  def require_admin
    redirect_to cookbook_path, alert: "Not authorised." unless current_user&.can_administer?
  end

  def require_write_access
    @policy = Policy.new(current_user, @recipe)
    redirect_to @recipe, alert: "Not authorised." unless @policy.can_update?
  end

  def recipe_params
    params.require(:recipe).permit(
      :title, :description, :recipe_image, :language_id,
      :serves, :makes, :cook_time, :classification, :body, :format,
      cuisine_ids: [], food_type_ids: [],
      ingredient_sections_attributes: [
        :id, :heading, :_destroy,
        { ingredients_attributes: %i[id quantity measurement name comment _destroy] }
      ]
    )
  end
end
