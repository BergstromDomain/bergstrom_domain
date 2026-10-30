# app/controllers/dossier/assignments_controller.rb

# Assignments under the signed-in user's Engagements. New takes an optional
# engagement_id to preselect the Engagement (from its "Add Assignment" button).
class Dossier::AssignmentsController < ApplicationController
  include Navigable
  before_action :require_dossier_access, only: %i[new create]
  before_action :set_assignment, only: %i[show edit update destroy]

  helper_method :engagement_choices

  def show
    redirect_to dossier_engagements_path, alert: "Not authorised." unless Policy.new(current_user, @assignment).can_read?
  end

  def new
    @assignment = Dossier::Assignment.new(engagement: engagement_choices.find_by(id: params[:engagement_id]))
  end

  def create
    @assignment = Dossier::Assignment.new(assignment_params)
    @assignment.engagement = engagement_choices.find_by(id: params.dig(:dossier_assignment, :engagement_id))
    if @assignment.save
      toast_created(@assignment)
      redirect_to @assignment
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to dossier_engagements_path, alert: "Not authorised." unless Policy.new(current_user, @assignment).can_update?
  end

  def update
    unless Policy.new(current_user, @assignment).can_update?
      redirect_to dossier_engagements_path, alert: "Not authorised." and return
    end
    previous_label = @assignment.to_toast_label
    if @assignment.update(assignment_params)
      toast_updated(@assignment, previous_label: previous_label)
      redirect_to @assignment
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless Policy.new(current_user, @assignment).can_delete?
      redirect_to dossier_engagements_path, alert: "Not authorised." and return
    end
    @assignment.destroy
    toast_deleted(@assignment)
    redirect_to @assignment.engagement
  end

  private

  def engagement_choices
    current_user.dossier_engagements.kept.newest_first.includes(:employer)
  end

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  def set_assignment
    @assignment = Dossier::Assignment.find(params[:id])
  end

  def assignment_params
    params.require(:dossier_assignment).permit(
      :client_id, :role_id, :location_id, :remote,
      :start_month, :start_day, :end_month, :end_day, :summary
    )
  end
end
