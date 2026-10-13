# app/controllers/languages_controller.rb

# Cookbook reference data — mirrors BlogCategoriesController: anyone can
# list/view, admins (or a Cookbook AppPermission override) can change.
class LanguagesController < ApplicationController
  include Navigable
  allow_unauthenticated_access only: %i[index show]
  before_action :resume_session_if_present
  before_action :set_language, only: %i[show edit update destroy]
  before_action :set_policy, only: %i[show edit update destroy]
  before_action :require_admin, only: %i[new create]

  def index
    @languages = Language.order("LOWER(name) ASC")
  end

  def show
  end

  def new
    @language = Language.new
  end

  def create
    @language = Language.new(language_params)
    if @language.save
      toast_created(@language)
      redirect_to @language
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to languages_path, alert: "Not authorised." unless @policy.can_update?
  end

  def update
    unless @policy.can_update?
      redirect_to languages_path, alert: "Not authorised." and return
    end
    previous_label = @language.to_toast_label
    if @language.update(language_params)
      toast_updated(@language, previous_label: previous_label)
      redirect_to @language
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @policy.can_delete?
      redirect_to languages_path, alert: "Not authorised." and return
    end
    @language.destroy
    if @language.errors.any?
      toast_error(@language)
      redirect_to language_path(@language)
    else
      toast_deleted(@language)
      redirect_to languages_path
    end
  end

  private

  def require_admin
    redirect_to languages_path, alert: "Not authorised." unless current_user&.can_administer?
  end

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end

  def set_policy
    @policy = Policy.new(current_user, @language)
  end

  def set_language
    @language = Language.friendly.find(params[:id])
  end

  def language_params
    params.require(:language).permit(:name, :code, :flag)
  end
end
