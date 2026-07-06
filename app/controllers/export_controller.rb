# app/controllers/export_controller.rb
class ExportController < ApplicationController
  before_action :require_authentication
  before_action :require_content_creator_or_above

  def create
    scopes = selected_scopes

    if scopes.empty?
      redirect_to import_export_path, alert: "Please select at least one scope to export."
      return
    end

    csv_data = ExportService.new(current_user, scopes).generate_csv
    filename = "events_export_#{Date.today.iso8601}.csv"

    send_data csv_data,
              type:        "text/csv; charset=utf-8",
              filename:    filename,
              disposition: "attachment"
  end

  private

  def selected_scopes
    scopes = []
    scopes << :restricted   if params[:scope_own]      == "1"
    scopes << :contacts     if params[:scope_contacts] == "1"
    scopes << :unrestricted if params[:scope_public]   == "1"
    scopes
  end

  def require_content_creator_or_above
    unless current_user.can_export?
      redirect_to import_export_path,
                  alert: "You need to be a content creator or above to export data."
    end
  end
end
