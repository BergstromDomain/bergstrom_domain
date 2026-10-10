# app/services/blog_post_zip_import_service.rb
require "zip"

# Imports a single BlogPost from a zip containing exactly one Markdown file
# plus any images it references by relative path. Unlike BlogPostImportService
# (CSV), this path carries no structured metadata — a real external Word-to-
# Markdown converter tool produces plain Markdown + images, not an app-specific
# schema, so the Category is chosen on the Import page and passed in, while
# Subject/Topic are left blank for the importing user to fill in afterward
# (Title is derived from the filename).
#
# Referenced images are rewritten into inline base64 data URIs at import time
# rather than kept as separate attachments — self-contained, and sidesteps the
# known PdfRenderingService limitation where a relative image URL can't
# resolve (no browsing-context origin — see docs/context-prompts/active/
# Feature_-_Import_and_Export.md's Deferred/Phase 2 section).
class BlogPostZipImportService
  Result = Struct.new(:imported_count, :failed_count, :errors, keyword_init: true)

  class ImportRowError < StandardError; end

  MARKDOWN_EXTENSIONS = %w[.md .markdown].freeze
  IMAGE_CONTENT_TYPES = { ".png" => "image/png", ".jpg" => "image/jpeg", ".jpeg" => "image/jpeg",
                           ".webp" => "image/webp" }.freeze

  def initialize(user, file, blog_category:)
    @user          = user
    @file          = file
    @blog_category = blog_category
  end

  def import
    import_zip!
    Result.new(imported_count: 1, failed_count: 0, errors: [])
  rescue ImportRowError => e
    Result.new(imported_count: 0, failed_count: 1, errors: [ { row: 1, message: e.message } ])
  end

  private

  def import_zip!
    entries = read_entries
    markdown_entries = entries.select { |name, _| MARKDOWN_EXTENSIONS.include?(File.extname(name).downcase) }

    if markdown_entries.size != 1
      raise ImportRowError, "The zip file must contain exactly one Markdown (.md/.markdown) file"
    end

    markdown_name, markdown_content = markdown_entries.first
    title = derive_title(markdown_name)
    body  = rewrite_images(markdown_content.dup.force_encoding("UTF-8"), entries)

    BlogPost.create!(
      user:           @user,
      title:          title,
      blog_category:  @blog_category,
      body:           body,
      format:         "raw",
      classification: :restricted
    )
  rescue ActiveRecord::RecordInvalid => e
    raise ImportRowError, e.record.errors.full_messages.to_sentence
  end

  def read_entries
    content = @file.respond_to?(:read) ? @file.read : File.read(@file)
    entries = {}

    Zip::File.open_buffer(content) do |zip|
      zip.each { |entry| entries[entry.name] = entry.get_input_stream.read unless entry.directory? }
    end

    entries
  rescue Zip::Error
    raise ImportRowError, "Could not read the uploaded file as a zip archive"
  end

  def derive_title(markdown_name)
    name = markdown_name.dup.force_encoding("UTF-8")
    File.basename(name, File.extname(name)).tr("_", " ").strip
  end

  def rewrite_images(body, entries)
    entries.each do |name, content|
      content_type = IMAGE_CONTENT_TYPES[File.extname(name).downcase]
      next unless content_type

      reference = [ name, File.basename(name) ].find { |ref| body.match?(/!\[[^\]]*\]\(#{Regexp.escape(ref)}\)/) }
      next unless reference

      data_uri = "data:#{content_type};base64,#{Base64.strict_encode64(content)}"
      body = body.gsub(/(!\[[^\]]*\]\()#{Regexp.escape(reference)}(\))/) { "#{$1}#{data_uri}#{$2}" }
    end

    body
  end
end
