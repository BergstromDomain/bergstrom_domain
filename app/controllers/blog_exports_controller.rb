# app/controllers/blog_exports_controller.rb
class BlogExportsController < ApplicationController
  include Navigable
  include PdfDownloadable
  include BlogPostFilterable

  before_action :require_can_export

  def index
    compute_filtered_blog_posts
  end

  def csv
    compute_filtered_blog_posts
    csv_data = BlogPostExportService.new(@posts).generate_csv
    filename = "BergstromDomain_Chronicle_#{Date.current.iso8601}.csv"

    send_data csv_data,
              type:        "text/csv; charset=utf-8",
              filename:    filename,
              disposition: "attachment"
  end

  def pdfs
    compute_filtered_blog_posts
    zip_data = ZipBundlingService.new(zip_entries_for(@posts)).generate
    filename = "BergstromDomain_Chronicle_#{Date.current.iso8601}.zip"

    send_data zip_data,
              type:        "application/zip",
              filename:    filename,
              disposition: "attachment"
  end

  private

  def require_can_export
    redirect_to chronicle_path, alert: "Not authorised." unless current_user&.can_export?
  end

  # Post titles aren't unique app-wide (only per-author), so two filtered
  # posts can collide on the same "Title.pdf" filename — de-duplicated with a
  # numeric suffix rather than silently overwriting one entry in the zip.
  def zip_entries_for(posts)
    seen = Hash.new(0)
    posts.each_with_object({}) do |post, entries|
      base = "#{post.title.gsub(' ', '_')}.pdf"
      seen[base] += 1
      filename = seen[base] == 1 ? base : base.sub(/\.pdf\z/, "_#{seen[base]}.pdf")
      entries[filename] = render_pdf(template: "blog_posts/pdf", assigns: { blog_post: post })
    end
  end
end
