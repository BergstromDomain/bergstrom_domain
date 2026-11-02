# app/controllers/dossier/periods_controller.rb

# One bench or gap period from the Timeline. Periods aren't stored — they're
# found again from the user's Engagements by their exact dates. Block 5 lists
# the courses and credentials completed during one here.
class Dossier::PeriodsController < ApplicationController
  include Navigable
  before_action :require_dossier_access

  def show
    timeline = Dossier::Timeline.new(current_user.dossier_engagements.kept.includes(:employer))
    @entry = timeline.period(Date.iso8601(params[:from]), Date.iso8601(params[:to]))
    not_on_timeline unless @entry
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
