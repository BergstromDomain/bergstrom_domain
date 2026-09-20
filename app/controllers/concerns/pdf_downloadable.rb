# app/controllers/concerns/pdf_downloadable.rb

# Small, app-agnostic glue between a controller's own view templates and
# PdfRenderingService — renders a template to a self-contained HTML string
# (no layout, since the PDF has no navigation/origin to hide) and hands it off
# for A4 PDF rendering. Shared by BlogPostsController#pdf and
# BlogExportsController#pdfs.
module PdfDownloadable
  extend ActiveSupport::Concern

  private

  def render_pdf(template:, assigns: {})
    html = render_to_string(template: template, layout: false, assigns: assigns)
    PdfRenderingService.new(html).render
  end
end
