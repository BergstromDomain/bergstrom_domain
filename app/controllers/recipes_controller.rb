# app/controllers/recipes_controller.rb
class RecipesController < ApplicationController
  include Navigable
  include FormatConvertible
  include ReturnTo

  allow_unauthenticated_access only: %i[show]
  before_action :resume_session_if_present, only: %i[show]
  before_action :require_create_access, only: %i[new create convert_format]

  def new
    settings = current_user.app_settings_for("recipes")
    @recipe = current_user.recipes.build(
      classification: settings.default_classification,
      language:       settings.effective_default_language
    )
    @recipe.ingredient_sections.build.ingredients.build
  end

  def show
    @recipe = Recipe.friendly.find(params[:id])
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
      @recipe.ingredient_sections.build.ingredients.build if @recipe.ingredient_sections.empty?
      render :new, status: :unprocessable_entity
    end
  end

  private

  def format_model = Recipe

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end

  def require_create_access
    redirect_to cookbook_path, alert: "Not authorised." unless Policy.new(current_user, :recipes).can_create?
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
