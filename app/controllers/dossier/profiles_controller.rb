# app/controllers/dossier/profiles_controller.rb

# The signed-in user's own Dossier Profile (one per user). The first visit
# opens the edit form pre-filled from the user's name; saving creates it.
class Dossier::ProfilesController < ApplicationController
  include Navigable
  before_action :require_dossier_access
  before_action :set_profile

  def show
    redirect_to edit_dossier_profile_path if @profile.new_record?
  end

  def edit
  end

  def update
    creating = @profile.new_record?
    previous_label = @profile.to_toast_label
    if @profile.update(profile_params)
      creating ? toast_created(@profile) : toast_updated(@profile, previous_label: previous_label)
      redirect_to dossier_profile_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  def set_profile
    @profile = Dossier::Profile.for(current_user)
  end

  def profile_params
    params.require(:dossier_profile).permit(
      :display_name, :headline, :location_id, :email, :phone, :website_url, :linkedin_url, :github_url,
      :summary, :summary_first_person, :summary_third_person, :third_person_name, :pronouns
    )
  end
end
