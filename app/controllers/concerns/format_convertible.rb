# app/controllers/concerns/format_convertible.rb

# The Raw <-> Formatted editor's round trip (markdown_editor_controller.js):
# Markdown to HTML for the Quill tab, HTML back to Markdown for storage.
# The including controller names its MarkdownRenderable model in
# #format_model and guards the action with its own create access check.
module FormatConvertible
  extend ActiveSupport::Concern

  def convert_format
    case params[:source]
    when "markdown"
      render json: { html: format_model.render_markdown(params[:content]) }
    when "html"
      render json: { markdown: ReverseMarkdown.convert(params[:content].to_s) }
    else
      head :bad_request
    end
  end
end
