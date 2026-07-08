# app/controllers/import_controller.rb
class ImportController < ApplicationController
  allow_unauthenticated_access only: %i[ template ]

  before_action :require_authentication,          only: %i[ create ]
  before_action :require_content_creator_or_above, only: %i[ create ]

  def create
    file = params[:file]

    if file.blank?
      redirect_to import_export_path, alert: "Please choose a CSV file to import."
      return
    end

    unless file.original_filename.to_s.downcase.end_with?(".csv")
      redirect_to import_export_path, alert: "The uploaded file must be a CSV file."
      return
    end

    @import_result = ImportService.new(current_user, file).import
    render "pages/import_export"
  end

  def template
    csv_data = ImportTemplateService.new.generate_csv

    send_data csv_data,
              type:        "text/csv; charset=utf-8",
              filename:    "import_template.csv",
              disposition: "attachment"
  end

  private

  def require_content_creator_or_above
    unless current_user.can_export?
      redirect_to import_export_path,
                  alert: "You need to be a content creator or above to import data."
    end
  end
end
