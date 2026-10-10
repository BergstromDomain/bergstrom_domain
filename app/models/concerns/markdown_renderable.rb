# app/models/concerns/markdown_renderable.rb
module MarkdownRenderable
  extend ActiveSupport::Concern

  class_methods do
    # header_ids: nil turns off Commonmarker's default heading-anchor-link
    # generation — not needed by any including model's editor/reader.
    # syntax_highlighter theme: InspiredGitHub is a light theme matching this
    # site's light background (the built-in default is a dark theme).
    def render_markdown(markdown)
      # nil.to_s is US-ASCII "", not UTF-8 — Commonmarker rejects anything
      # that isn't explicitly UTF-8, even an empty string.
      text = markdown.to_s.dup.force_encoding(Encoding::UTF_8)
      Commonmarker.to_html(text,
        options: { render: { unsafe: true }, extension: { header_ids: nil } },
        plugins: { syntax_highlighter: { theme: "InspiredGitHub" } })
    end
  end

  def rendered_body
    self.class.render_markdown(body)
  end
end
