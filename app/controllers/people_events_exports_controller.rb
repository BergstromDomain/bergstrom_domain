# app/controllers/people_events_exports_controller.rb

# "Download People and Events" — same filter UI/engine as Filter People and
# Events, plus a CSV download that always matches what's on screen. Mirrors
# BlogExportsController; replaces the old PagesController#import_export +
# ExportController pair (which exposed classification as a user-selectable
# checkbox scope — now implicit, via the same visible_people_scope/
# visible_events_scope every other Occasions page already uses).
class PeopleEventsExportsController < ApplicationController
  include Navigable
  include PeopleEventsFilterable

  before_action :require_can_export

  def index
    compute_filtered_people_events_rows
  end

  def csv
    compute_filtered_people_events_rows
    csv_data = ExportService.new(@rows).generate_csv
    filename = "BergstromDomain_Occasions_#{Date.current.iso8601}.csv"

    send_data csv_data,
              type:        "text/csv; charset=utf-8",
              filename:    filename,
              disposition: "attachment"
  end

  private

  def require_can_export
    redirect_to event_tracker_path, alert: "Not authorised." unless current_user&.can_export?
  end
end
