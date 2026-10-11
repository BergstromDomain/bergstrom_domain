# app/controllers/food_types_controller.rb

# Cookbook reference data — mirrors BlogCategoriesController: anyone can
# list/view, admins (or a Cookbook AppPermission override) can change.
class FoodTypesController < ApplicationController
  include Navigable
  allow_unauthenticated_access only: %i[index show]
  before_action :resume_session_if_present
  before_action :set_food_type, only: %i[show edit update destroy]
  before_action :set_policy, only: %i[show edit update destroy]
  before_action :require_admin, only: %i[new create]

  def index
    @food_types = FoodType.order("LOWER(name) ASC")
  end

  def show
  end

  def new
    @food_type = FoodType.new
  end

  def create
    @food_type = FoodType.new(food_type_params)
    if @food_type.save
      toast_created(@food_type)
      redirect_to @food_type
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to food_types_path, alert: "Not authorised." unless @policy.can_update?
  end

  def update
    unless @policy.can_update?
      redirect_to food_types_path, alert: "Not authorised." and return
    end
    previous_label = @food_type.to_toast_label
    if @food_type.update(food_type_params)
      toast_updated(@food_type, previous_label: previous_label)
      redirect_to @food_type
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @policy.can_delete?
      redirect_to food_types_path, alert: "Not authorised." and return
    end
    @food_type.destroy
    if @food_type.errors.any?
      toast_error(@food_type)
      redirect_to food_type_path(@food_type)
    else
      toast_deleted(@food_type)
      redirect_to food_types_path
    end
  end

  private

  def require_admin
    redirect_to food_types_path, alert: "Not authorised." unless current_user&.can_administer?
  end

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end

  def set_policy
    @policy = Policy.new(current_user, @food_type)
  end

  def set_food_type
    @food_type = FoodType.friendly.find(params[:id])
  end

  def food_type_params
    params.require(:food_type).permit(:name, :description, :icon)
  end
end
