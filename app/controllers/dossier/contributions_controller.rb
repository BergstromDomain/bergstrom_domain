# app/controllers/dossier/contributions_controller.rb

# The signed-in user's Contributions (talks, articles, community work), at
# /dossier/contributions, grouped by kind, newest first. Show follows the
# Contribution's classification; only the owner and admins change it.
# Deleting is soft: Deleted lists the user's own, and Restore brings one back.
class Dossier::ContributionsController < ApplicationController
  include Navigable
  before_action :require_dossier_access, only: %i[index deleted new create]
  before_action :set_contribution, only: %i[show edit update destroy]

  helper_method :engagement_choices

  def index
    @groups = current_user.dossier_contributions.kept.newest_first.includes(:event, contribution_skills: :skill)
                          .group_by(&:kind)
                          .sort_by { |kind, _| Dossier::Contribution::KINDS.keys.index(kind) }
  end

  def deleted
    @contributions = current_user.dossier_contributions.discarded.order(deleted_at: :desc)
  end

  def show
    unless Policy.new(current_user, @contribution).can_read?
      redirect_to dossier_contributions_path, alert: "Not authorised." and return
    end
    return unless @contribution.files_visible_to?(current_user)

    ActiveRecord::Associations::Preloader.new(records: [ @contribution ], associations: { files_attachments: :blob }).call
  end

  def new
    @contribution = current_user.dossier_contributions.build(kind: "talk")
  end

  def create
    @contribution = current_user.dossier_contributions.build(contribution_params)
    @contribution.engagement = engagement_choices.find_by(id: params.dig(:dossier_contribution, :engagement_id))
    if @contribution.save
      toast_created(@contribution)
      redirect_to @contribution
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to dossier_contributions_path, alert: "Not authorised." unless Policy.new(current_user, @contribution).can_update?
  end

  def update
    unless Policy.new(current_user, @contribution).can_update?
      redirect_to dossier_contributions_path, alert: "Not authorised." and return
    end
    previous_label = @contribution.to_toast_label
    @contribution.assign_attributes(contribution_params)
    @contribution.engagement = engagement_choices.find_by(id: params.dig(:dossier_contribution, :engagement_id))
    if @contribution.save
      toast_updated(@contribution, previous_label: previous_label)
      redirect_to @contribution
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless Policy.new(current_user, @contribution).can_delete?
      redirect_to dossier_contributions_path, alert: "Not authorised." and return
    end
    @contribution.soft_delete!
    toast_deleted(@contribution)
    redirect_to dossier_contributions_path
  end

  def restore
    contribution = Dossier::Contribution.discarded.find(params[:id])
    if Policy.new(current_user, contribution).can_update?
      contribution.restore!
      flash[:success] = "#{contribution.to_toast_label} has been successfully restored"
      redirect_to deleted_dossier_contributions_path
    else
      redirect_to dossier_contributions_path, alert: "Not authorised."
    end
  end

  private

  # The Contribution owner's kept Engagements (an admin editing sees the owner's).
  def engagement_choices
    owner = @contribution&.persisted? ? @contribution.user : current_user
    owner.dossier_engagements.kept.includes(:employer).newest_first
  end

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  # Kept ones only: a deleted one is a 404 until it's restored.
  def set_contribution
    scope = Dossier::Contribution.kept
    scope = scope.includes(:event, :engagement, contribution_skills: :skill) if %w[show edit].include?(action_name)
    @contribution = scope.find(params[:id])
  end

  def contribution_params
    params.require(:dossier_contribution).permit(:kind, :title, :event_id, :start_year, :start_month_number, :start_day,
                                                 :location, :url, :presented_as, :description, :skills_text, files: [])
  end
end
