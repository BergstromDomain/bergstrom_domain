# app/controllers/recipes_controller.rb
class RecipesController < ApplicationController
  include Navigable
  include FormatConvertible
  include ReturnTo

  allow_unauthenticated_access only: %i[show]
  before_action :resume_session_if_present, only: %i[show]
  before_action :set_recipe,            only: %i[show edit update publish unpublish destroy restore]
  before_action :require_create_access, only: %i[new create convert_format]
  before_action :require_write_access,  only: %i[edit update publish unpublish]
  before_action :require_delete_access, only: %i[destroy]
  before_action :require_admin,         only: %i[deleted restore]

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
  # "DECISIONS (Block 5)" in docs/context-prompts/active/App_-_Cookbook.md.
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
      :title, :description, :recipe_image, :cuisine_id, :food_type_id, :language_id,
      :serves, :makes, :cook_time, :classification, :body, :format,
      ingredient_sections_attributes: [
        :id, :heading, :_destroy,
        { ingredients_attributes: %i[id quantity measurement name comment _destroy] }
      ]
    )
  end
end
