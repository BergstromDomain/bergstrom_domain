# app/controllers/dossier/engagements_controller.rb

# The signed-in user's Engagements. Delete is a soft delete (deleted_at) that
# hides the Engagement's Assignments and Achievements too; Deleted lists the
# user's own and Restore brings one back with everything under it.
class Dossier::EngagementsController < ApplicationController
  include Navigable
  before_action :require_dossier_access, only: %i[index deleted new create]
  before_action :set_engagement, only: %i[show edit update destroy restore]

  # The Professional/Personal ticks come from the submitted filter, which is
  # saved to the user's Dossier settings, or else from those settings. Gaps
  # are worked out from every Professional Engagement and hidden along with them.
  def index
    timeline = Dossier::Timeline.new(current_user.dossier_engagements.kept)
    @kinds = timeline_kinds
    @all_entries = timeline.entries
    @entries = @all_entries.select { |entry| @kinds.include?(entry_kind(entry)) }
    # Logos and names only for the Engagements shown.
    shown = @entries.filter_map(&:engagement)
    ActiveRecord::Associations::Preloader.new(
      records: shown, associations: { employer: { logo_attachment: :blob }, assignments: { client: { logo_attachment: :blob } } }
    ).call
  end

  def deleted
    @engagements = current_user.dossier_engagements.discarded.includes(:employer).order(deleted_at: :desc)
  end

  def show
    unless Policy.new(current_user, @engagement).can_read?
      redirect_to dossier_engagements_path, alert: "Not authorised." and return
    end
    ActiveRecord::Associations::Preloader.new(records: [ @engagement ], associations: { assignments: { client: { logo_attachment: :blob } } }).call
    @contributions = @engagement.contributions.kept.newest_first.includes(:event, contribution_skills: :skill)
                                .select { |contribution| Policy.new(current_user, contribution).can_read? }
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

  def restore
    if Policy.new(current_user, @engagement).can_update?
      @engagement.restore!
      flash[:success] = "#{@engagement.to_toast_label} has been successfully restored"
      redirect_to deleted_dossier_engagements_path
    else
      redirect_to dossier_engagements_path, alert: "Not authorised."
    end
  end

  private

  def timeline_kinds
    setting = current_user.app_settings_for("dossier")
    if params.key?(:kinds)
      setting.timeline_kinds = params[:kinds]
      setting.save! if setting.changed?
    end
    setting.timeline_kinds
  end

  def entry_kind(entry)
    entry.kind == :gap || !entry.engagement.personal? ? "professional" : "personal"
  end

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  def set_engagement
    @engagement = Dossier::Engagement.find(params[:id])
  end

  def engagement_params
    params.require(:dossier_engagement).permit(
      :employer_id, :employment_type_id, :position_title,
      :start_year, :start_month_number, :start_day, :end_year, :end_month_number, :end_day, :summary
    )
  end
end
