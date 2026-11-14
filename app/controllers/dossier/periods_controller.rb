# app/controllers/dossier/periods_controller.rb

# One bench or gap period from the Timeline. Periods aren't stored — they're
# found again from the user's Engagements by their exact dates. Lists the
# user's Credentials (of any type) completed during the period.
class Dossier::PeriodsController < ApplicationController
  include Navigable
  before_action :require_dossier_access

  def show
    timeline = Dossier::Timeline.new(current_user.dossier_engagements.kept)
    @entry = timeline.period(Date.iso8601(params[:from]), Date.iso8601(params[:to]))
    return not_on_timeline unless @entry
    # A Bench names its Engagement; only that one's employer is shown.
    ActiveRecord::Associations::Preloader.new(records: [ @entry.engagement ].compact, associations: :employer).call

    @credentials = current_user.dossier_credentials.kept.includes(:provider)
                               .completed_during(@entry.period.from, @entry.period.to)
  rescue Date::Error
    not_on_timeline
  end

  private

  def not_on_timeline
    redirect_to dossier_engagements_path, alert: "That period isn't on your Timeline."
  end

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end
end
