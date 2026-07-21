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

  private

  def settings_params
    params.require(:user).permit(:first_name, :last_name, :email_address, :profile_image, :start_page)
  end
end
