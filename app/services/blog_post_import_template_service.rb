# app/services/blog_post_import_template_service.rb
require "csv"

class BlogPostImportTemplateService
  def generate_csv
    CSV.generate(headers: true, encoding: "UTF-8") do |csv|
      csv << BlogPostImportService::HEADERS

      BlogCategory.order("LOWER(name)").each do |category|
        csv << [ "[Title]", category.name, "", "", "[Body]" ]
      end
    end
  end
end
