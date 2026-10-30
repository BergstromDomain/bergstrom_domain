# app/controllers/dossier/engagements_controller.rb

# The signed-in user's Engagements. Delete is a soft delete (deleted_at);
# restoring and the 30-day purge come with Achievements in Block 3.
class Dossier::EngagementsController < ApplicationController
  include Navigable
  before_action :require_dossier_access, only: %i[index new create]
  before_action :set_engagement, only: %i[show edit update destroy]

  def index
    @timeline = Dossier::Timeline.new(current_user.dossier_engagements.kept.includes(:employer))
  end

  def show
    redirect_to dossier_engagements_path, alert: "Not authorised." unless Policy.new(current_user, @engagement).can_read?
  end

  def new
    @engagement = current_user.dossier_engagements.build
  end

  def create
    @engagement = current_user.dossier_engagements.build(engagement_params)
    if @engagement.save
      toast_created(@engagement)
      redirect_to @engagement
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to dossier_engagements_path, alert: "Not authorised." unless Policy.new(current_user, @engagement).can_update?
  end

  def update
    unless Policy.new(current_user, @engagement).can_update?
      redirect_to dossier_engagements_path, alert: "Not authorised." and return
    end
    previous_label = @engagement.to_toast_label
    if @engagement.update(engagement_params)
      toast_updated(@engagement, previous_label: previous_label)
      redirect_to @engagement
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless Policy.new(current_user, @engagement).can_delete?
      redirect_to dossier_engagements_path, alert: "Not authorised." and return
    end
    @engagement.soft_delete!
    toast_deleted(@engagement)
    redirect_to dossier_engagements_path
  end

  private

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  def set_engagement
    @engagement = Dossier::Engagement.find(params[:id])
  end

  def engagement_params
    params.require(:dossier_engagement).permit(
      :employer_id, :employment_type_id, :position_title,
      :start_month, :start_day, :end_month, :end_day, :summary
    )
  end
end
