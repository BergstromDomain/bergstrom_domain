class SettingsController < ApplicationController
  include Navigable

  before_action :require_authentication

  def show
  end

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    original_email = @user.email_address

    if @user.update(settings_params)
      if @user.email_address != original_email
        @user.update_column(:email_verified_at, nil)
      end
      redirect_to settings_path, notice: "Your details have been updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_password
    if Current.user.authenticate(params[:current_password])
      if Current.user.update(
           password: params[:password],
           password_confirmation: params[:password_confirmation]
         )
        redirect_to settings_path, notice: "Password updated."
      else
        @password_errors = Current.user.errors
        render :show, status: :unprocessable_entity
      end
    else
      @password_errors = ActiveModel::Errors.new(Current.user).tap do |e|
        e.add(:base, "Current password is incorrect")
      end
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    Current.user.update_column(:status, "suspended")
    terminate_session
    redirect_to root_path, notice: "Your account has been suspended."
  end

  def resend_verification
    redirect_to settings_path, notice: "Verification email sent."
  end

  def preferences
    @user = Current.user
  end

  def update_preferences
    @user = Current.user

    if @user.update(preferences_params)
      redirect_to preferences_settings_path, notice: "Preferences updated."
    else
      render :preferences, status: :unprocessable_entity
    end
  end

  def chronicle_settings
    @user_app_setting = Current.user.app_settings_for("blog_posts")
  end

  def update_chronicle_settings
    @user_app_setting = Current.user.app_settings_for("blog_posts")

    if @user_app_setting.update(app_setting_params)
      redirect_to chronicle_settings_path, notice: "Chronicle Settings updated."
    else
      render :chronicle_settings, status: :unprocessable_entity
    end
  end

  def occasions_settings
    @user_app_setting = Current.user.app_settings_for("event_tracker")
  end

  def update_occasions_settings
    @user_app_setting = Current.user.app_settings_for("event_tracker")

    if @user_app_setting.update(app_setting_params)
      redirect_to occasions_settings_path, notice: "Occasions Settings updated."
    else
      render :occasions_settings, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user).permit(:first_name, :last_name, :email_address, :profile_image)
  end

  def preferences_params
    attrs = params.require(:user).permit(:start_page, default_classifications: [])
    attrs[:default_classifications] = attrs[:default_classifications].reject(&:blank?) if attrs.key?(:default_classifications)
    attrs
  end

  def app_setting_params
    attrs = params.require(:user_app_setting).permit(:start_page, :default_classification)
    attrs[:start_page] = attrs[:start_page].presence if attrs.key?(:start_page)
    attrs
  end
end
