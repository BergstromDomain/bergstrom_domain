# app/controllers/blog_imports_controller.rb
class BlogImportsController < ApplicationController
  include Navigable

  before_action :require_can_export

  def new
  end

  def create
    file = params[:file]

    if file.blank?
      redirect_to new_blog_import_path, alert: "Please choose a CSV file to import."
      return
    end

    unless file.original_filename.to_s.downcase.end_with?(".csv")
      redirect_to new_blog_import_path, alert: "The uploaded file must be a CSV file."
      return
    end

    @import_result = BlogPostImportService.new(current_user, file).import
    render :new
  end

  def template
    csv_data = BlogPostImportTemplateService.new.generate_csv

    send_data csv_data,
              type:        "text/csv; charset=utf-8",
              filename:    "blog_posts_import_template.csv",
              disposition: "attachment"
  end

  private

  def require_can_export
    redirect_to chronicle_path, alert: "Not authorised." unless current_user&.can_export?
  end
end
