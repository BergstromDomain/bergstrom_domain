# app/services/blog_post_export_service.rb
require "csv"

class BlogPostExportService
  HEADERS = [ "Title", "Category", "Subject", "Topic", "Author", "Created", "Published", "Body (Markdown)" ].freeze

  def initialize(posts)
    @posts = posts
  end

  def generate_csv
    CSV.generate(headers: true, encoding: "UTF-8") do |csv|
      csv << HEADERS

      @posts.each do |post|
        csv << [
          post.title,
          post.blog_category&.name,
          post.subject,
          post.topic,
          "#{post.user.first_name} #{post.user.last_name}",
          post.created_at.strftime("%d-%b-%Y"),
          post.published? ? "Yes" : "No",
          post.body
        ]
      end
    end
  end
end
