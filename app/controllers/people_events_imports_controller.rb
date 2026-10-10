# app/controllers/people_events_imports_controller.rb

# "Import People and Events" — mirrors BlogImportsController's dedicated
# page/layout exactly (one unconditional require_can_export gate, no
# separate public template download); replaces the old combined
# PagesController#import_export + ImportController pair, which left the CSV
# template downloadable by anyone signed in or not. Same ImportService/
# ImportTemplateService and CSV format underneath — only the page and its
# access gate change.
class PeopleEventsImportsController < ApplicationController
  include Navigable

  before_action :require_can_export

  def new
  end

  def create
    file = params[:file]

    if file.blank?
      redirect_to new_people_events_import_path, alert: "Please choose a CSV file to import."
      return
    end

    unless file.original_filename.to_s.downcase.end_with?(".csv")
      redirect_to new_people_events_import_path, alert: "The uploaded file must be a CSV file."
      return
    end

    @import_result = ImportService.new(current_user, file).import
    render :new
  end

  def template
    csv_data = ImportTemplateService.new.generate_csv

    send_data csv_data,
              type:        "text/csv; charset=utf-8",
              filename:    "people_events_import_template.csv",
              disposition: "attachment"
  end

  private

  def require_can_export
    redirect_to event_tracker_path, alert: "Not authorised." unless current_user&.can_export?
  end
end
