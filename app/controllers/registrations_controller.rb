# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.status = :pending

    if params.dig(:user, :profile_image).blank?
      @user.errors.add(:profile_image, "must be attached")
      render :new, status: :unprocessable_entity and return
    end

    if @user.save
      @user.profile_image.attach(params[:user][:profile_image])
      # TODO: send verification email via UserMailer (Post #19)
      redirect_to root_path, notice: "Your sign up request has been submitted."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.expect(user: [
      :first_name,
      :last_name,
      :email_address,
      :password,
      :password_confirmation,
      :message_to_admin
    ])
  end
end
