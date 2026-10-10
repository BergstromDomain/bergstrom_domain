# app/controllers/blog_imports_controller.rb
class BlogImportsController < ApplicationController
  include Navigable

  before_action :require_can_export

  def new
  end

  def create
    file = params[:file]

    if file.blank?
      redirect_to new_blog_import_path, alert: "Please choose a file to import."
      return
    end

    service = import_service_for(file)
    if service.nil?
      redirect_to new_blog_import_path, alert: "The uploaded file must be a CSV or ZIP file."
      return
    end

    if service.is_a?(BlogPostZipImportService) && zip_category.nil?
      redirect_to new_blog_import_path, alert: "Please choose a Category for a ZIP import."
      return
    end

    @import_result = service.import
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

  def import_service_for(file)
    case File.extname(file.original_filename.to_s).downcase
    when ".csv" then BlogPostImportService.new(current_user, file)
    when ".zip" then BlogPostZipImportService.new(current_user, file, blog_category: zip_category)
    end
  end

  # Only used for a ZIP upload — a CSV carries its own Category on every row.
  def zip_category
    return @zip_category if defined?(@zip_category)

    @zip_category = BlogCategory.find_by(id: params[:blog_category_id])
  end

  def require_can_export
    redirect_to chronicle_path, alert: "Not authorised." unless current_user&.can_export?
  end
end
