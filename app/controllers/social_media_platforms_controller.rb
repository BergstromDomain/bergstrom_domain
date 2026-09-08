# app/controllers/social_media_platforms_controller.rb
class SocialMediaPlatformsController < ApplicationController
  include Navigable
  allow_unauthenticated_access only: %i[index show]
  before_action :resume_session_if_present
  before_action :set_social_media_platform, only: %i[show edit update destroy]
  before_action :set_policy,                only: %i[show edit update destroy]
  before_action :require_admin,             only: %i[new create]

  def index
    @social_media_platforms = SocialMediaPlatform.order("LOWER(name) ASC")
  end

  def show
  end

  def new
    @social_media_platform = SocialMediaPlatform.new
  end

  def create
    @social_media_platform = SocialMediaPlatform.new(social_media_platform_params)
    if @social_media_platform.save
      toast_created(@social_media_platform)
      redirect_to @social_media_platform
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to social_media_platforms_path, alert: "Not authorised." unless @policy.can_update?
  end

  def update
    unless @policy.can_update?
      redirect_to social_media_platforms_path, alert: "Not authorised." and return
    end
    previous_label = @social_media_platform.to_toast_label
    if @social_media_platform.update(social_media_platform_params)
      toast_updated(@social_media_platform, previous_label: previous_label)
      redirect_to @social_media_platform
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @policy.can_delete?
      redirect_to social_media_platforms_path, alert: "Not authorised." and return
    end
    @social_media_platform.destroy
    if @social_media_platform.errors.any?
      toast_error(@social_media_platform)
      redirect_to social_media_platform_path(@social_media_platform)
    else
      toast_deleted(@social_media_platform)
      redirect_to social_media_platforms_path
    end
  end

  private

  def require_admin
    unless current_user&.can_administer?
      redirect_to social_media_platforms_path, alert: "Not authorised."
    end
  end

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end

  def set_policy
    @policy = Policy.new(current_user, @social_media_platform)
  end

  def set_social_media_platform
    @social_media_platform = SocialMediaPlatform.friendly.find(params[:id])
  end

  def social_media_platform_params
    params.require(:social_media_platform).permit(:name, :url, :description, :logo)
  end
end
