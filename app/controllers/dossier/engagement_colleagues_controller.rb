# app/controllers/dossier/engagement_colleagues_controller.rb

# An Engagement's Colleagues (consultants you worked with during it, on no
# shared Assignment), added and edited from its page. Only those who can see
# them (the owner and Admins) and may update the Engagement get in, and not
# while it's deleted.
class Dossier::EngagementColleaguesController < ApplicationController
  include Navigable
  include Dossier::LinksPeople
  before_action :set_engagement
  before_action :require_access
  before_action :set_colleague, only: %i[edit update destroy]

  def new
    @colleague = @engagement.colleagues.build
    pick_person(@colleague, params[:person_id])
    find_people
  end

  def create
    @colleague = @engagement.colleagues.build
    pick_person(@colleague, params.dig(:dossier_engagement_colleague, :person_id))
    assign_contact(@colleague, contact_params(:dossier_engagement_colleague))
    if @colleague.save
      toast_created(@colleague)
      redirect_to colleagues_path
    else
      find_people
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    previous_label = @colleague.to_toast_label
    assign_contact(@colleague, contact_params(:dossier_engagement_colleague))
    if @colleague.save
      toast_updated(@colleague, previous_label: previous_label)
      redirect_to colleagues_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @colleague.destroy
    toast_deleted(@colleague)
    redirect_to colleagues_path
  end

  private

  def contact_owner = @engagement.user

  def set_engagement
    @engagement = Dossier::Engagement.find(params[:engagement_id])
  end

  def require_access
    return if @engagement.private_details_visible_to?(current_user) && Policy.new(current_user, @engagement).can_update? &&
              @engagement.deleted_at.nil?

    redirect_to dossier_engagements_path, alert: "Not authorised."
  end

  # Only this Engagement's: another's id is a 404.
  def set_colleague
    @colleague = @engagement.colleagues.includes(Dossier::ContactDetails::PRELOAD).find(params[:id])
  end

  def colleagues_path = dossier_engagement_path(@engagement, anchor: "colleagues")
end
