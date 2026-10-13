# app/controllers/cuisines_controller.rb

# Cookbook reference data — mirrors BlogCategoriesController: anyone can
# list/view, admins (or a Cookbook AppPermission override) can change.
class CuisinesController < ApplicationController
  include Navigable
  allow_unauthenticated_access only: %i[index show]
  before_action :resume_session_if_present
  before_action :set_cuisine, only: %i[show edit update destroy]
  before_action :set_policy, only: %i[show edit update destroy]
  before_action :require_admin, only: %i[new create]

  def index
    @cuisines = Cuisine.order("LOWER(name) ASC")
  end

  def show
  end

  def new
    @cuisine = Cuisine.new
  end

  def create
    @cuisine = Cuisine.new(cuisine_params)
    if @cuisine.save
      toast_created(@cuisine)
      redirect_to @cuisine
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to cuisines_path, alert: "Not authorised." unless @policy.can_update?
  end

  def update
    unless @policy.can_update?
      redirect_to cuisines_path, alert: "Not authorised." and return
    end
    previous_label = @cuisine.to_toast_label
    if @cuisine.update(cuisine_params)
      toast_updated(@cuisine, previous_label: previous_label)
      redirect_to @cuisine
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @policy.can_delete?
      redirect_to cuisines_path, alert: "Not authorised." and return
    end
    @cuisine.destroy
    if @cuisine.errors.any?
      toast_error(@cuisine)
      redirect_to cuisine_path(@cuisine)
    else
      toast_deleted(@cuisine)
      redirect_to cuisines_path
    end
  end

  private

  def require_admin
    redirect_to cuisines_path, alert: "Not authorised." unless current_user&.can_administer?
  end

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end

  def set_policy
    @policy = Policy.new(current_user, @cuisine)
  end

  def set_cuisine
    @cuisine = Cuisine.friendly.find(params[:id])
  end

  def cuisine_params
    params.require(:cuisine).permit(:name, :description, :flag)
  end
end
