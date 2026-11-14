# app/controllers/dossier/assignments_controller.rb

# Assignments under the signed-in user's Engagements. New takes an optional
# engagement_id to preselect the Engagement (from its "Add Assignment" button).
# Delete is a soft delete that hides its Achievements and Training too;
# Deleted lists the user's own (those whose Engagement isn't deleted as well)
# and Restore brings one back with everything under it.
class Dossier::AssignmentsController < ApplicationController
  include Navigable
  before_action :require_dossier_access, only: %i[deleted new create]
  before_action :set_assignment, only: %i[show edit update destroy restore move]

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
      warn_about_uncovered_skills
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

  # Up/Down on the Engagement page.
  def move
    unless Policy.new(current_user, @assignment).can_update?
      redirect_to dossier_engagements_path, alert: "Not authorised." and return
    end
    @assignment.move!(params[:direction])
    # Back to the same URL, so Turbo refreshes the page in place, keeping the scroll.
    redirect_to dossier_engagement_path(@assignment.engagement)
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
    @assignment = assignment_scope.find(params[:id])
  end

  # Only what each action reads, so nothing is loaded unused: the page shows
  # the client, Tech Stack and Achievements; the form edits the Tech Stack.
  def assignment_scope
    case action_name
    when "show" then Dossier::Assignment.includes({ client: { logo_attachment: :blob } }, assignment_skills: :skill, achievements: { achievement_skills: :skill })
    when "edit", "update" then Dossier::Assignment.includes(assignment_skills: :skill)
    else Dossier::Assignment
    end
  end

  # Tech Stack Skills no Achievement names, System Under Test and the exempt
  # categories aside (Dossier::TechStackCoverage).
  def warn_about_uncovered_skills
    uncovered = Dossier::TechStackCoverage.new(@assignment.reload).uncovered
    flash[:warning] = "Not in any Achievement: #{uncovered.map(&:display_name).join(', ')}" if uncovered.any?
  end

  def assignment_params
    params.require(:dossier_assignment).permit(
      :client_id, :project, :role_id, :location_id, :remote,
      :start_year, :start_month_number, :start_day, :end_year, :end_month_number, :end_day, :summary,
      :systems_under_test_text, :systems_under_test_na, category_skills_text: {}
    )
  end
end
