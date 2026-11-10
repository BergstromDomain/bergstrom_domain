# app/controllers/dossier/assignments_controller.rb

# Assignments under the signed-in user's Engagements. New takes an optional
# engagement_id to preselect the Engagement (from its "Add Assignment" button).
# Delete is a soft delete that hides its Achievements and Training too;
# Deleted lists the user's own (those whose Engagement isn't deleted as well)
# and Restore brings one back with everything under it.
class Dossier::AssignmentsController < ApplicationController
  include Navigable
  before_action :require_dossier_access, only: %i[deleted new create]
  before_action :set_assignment, only: %i[show edit update destroy restore]

  helper_method :engagement_choices

  def deleted
    @assignments = Dossier::Assignment.discarded.where(user: current_user)
                                      .joins(:engagement).merge(Dossier::Engagement.kept)
                                      .includes(:client, :role, :all_achievements, engagement: :employer)
                                      .order(deleted_at: :desc)
  end

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
    redirect_to dossier_engagements_path, alert: "Not authorised." unless can_change?
  end

  def update
    unless can_change?
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
    unless Policy.new(current_user, @assignment).can_delete? && !@assignment.hidden?
      redirect_to dossier_engagements_path, alert: "Not authorised." and return
    end
    @assignment.soft_delete!
    toast_deleted(@assignment, info: "You can restore it, with its Achievements, from Deleted Assignments for 30 days.")
    redirect_to @assignment.engagement
  end

  def restore
    unless Policy.new(current_user, @assignment).can_update? && @assignment.deleted_at && !@assignment.engagement.deleted_at
      redirect_to dossier_engagements_path, alert: "Not authorised." and return
    end
    if @assignment.fits_within?(@assignment.engagement)
      @assignment.restore!
      flash[:success] = "#{@assignment.to_toast_label} has been successfully restored"
    else
      flash[:alert] = "#{@assignment.to_toast_label} no longer fits within its Engagement's dates " \
                      "(#{@assignment.engagement.date_range}). Change the Engagement's dates, then restore it."
    end
    redirect_to deleted_dossier_assignments_path
  end

  private

  # A deleted Assignment can't be changed until it's restored.
  def can_change? = Policy.new(current_user, @assignment).can_update? && !@assignment.hidden?

  def engagement_choices
    current_user.dossier_engagements.kept.newest_first.includes(:employer)
  end

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  def set_assignment
    @assignment = Dossier::Assignment.includes(:client, assignment_skills: :skill,
                                                         achievements: { achievement_skills: :skill }).find(params[:id])
  end

  def assignment_params
    params.require(:dossier_assignment).permit(
      :client_id, :project, :role_id, :location_id, :remote,
      :start_year, :start_month_number, :start_day, :end_year, :end_month_number, :end_day, :summary,
      *Dossier::TechStack::SLOTS.values.flat_map { |plural| [ :"#{plural}_text", :"#{plural}_na" ] }
    )
  end
end
