# app/services/blog_post_full_export_service.rb
require "csv"

# Admin-only PROD-migration export (Import/Export planning doc's Block 5) —
# unlike BlogPostExportService's plain CSV (kept as-is for everyday use),
# this bundles every post's full metadata plus its actual image bytes into
# one self-contained zip: a `csv/` folder with a richer CSV (Classification
# and every author, not just the primary one, added on top of the plain
# export's columns) and an `images/<slug>/` folder per post, so two posts'
# images can never collide. Deliberately export-only for now — the matching
# admin import is a separate, still-open decision.
class BlogPostFullExportService
  HEADERS = [
    "Title", "Category", "Subject", "Topic", "Authors", "Classification",
    "Published", "Published Date", "Created Date", "Header Image", "Body (Markdown)"
  ].freeze

  MARKDOWN_IMAGE   = /!\[([^\]]*)\]\(([^)]+)\)/
  DATA_URI         = %r{\Adata:([^;]+);base64,(.+)\z}m
  BLOB_SIGNED_ID   = %r{/rails/active_storage/blobs/(?:redirect/|proxy/)?([^/]+)/}
  EXTENSIONS = {
    "image/png"  => ".png",
    "image/jpeg" => ".jpg",
    "image/gif"  => ".gif",
    "image/webp" => ".webp"
  }.freeze

  def initialize(posts)
    @posts = posts
  end

  def generate_zip
    images = {}
    rows = @posts.map do |post|
      row, post_images = row_and_images_for(post)
      images.merge!(post_images)
      row
    end

    csv_data = CSV.generate(headers: true, encoding: "UTF-8") do |csv|
      csv << HEADERS
      rows.each { |row| csv << row }
    end

    entries = { "csv/Chronicle_#{Date.current.iso8601}.csv" => csv_data }.merge(images)
    ZipBundlingService.new(entries).generate
  end

  private

  def row_and_images_for(post)
    images = {}

    header_path = nil
    if post.blog_image.attached?
      blob = post.blog_image.blob
      header_path = "images/#{post.slug}/blog_image#{extension_for(blob.content_type)}"
      images[header_path] = blob.download
    end

    body, body_images = rewrite_body_images(post)
    images.merge!(body_images)

    row = [
      post.title,
      post.blog_category.name,
      post.subject,
      post.topic,
      authors_list(post),
      post.classification,
      post.published? ? "Yes" : "No",
      post.published_at&.strftime("%d-%b-%Y"),
      post.created_at.strftime("%d-%b-%Y"),
      header_path,
      body
    ]

    [ row, images ]
  end

  # `has_many :authors, through: :blog_post_authors` has no guaranteed order
  # across databases — the primary author (post.user) is placed first
  # explicitly rather than relying on join-table row order.
  def authors_list(post)
    co_authors = post.authors.where.not(id: post.user_id)
    ([ post.user ] + co_authors).map { |author| "#{author.first_name} #{author.last_name}" }.join("; ")
  end

  def rewrite_body_images(post)
    images = {}
    counter = 0

    body = post.body.to_s.gsub(MARKDOWN_IMAGE) do
      alt = Regexp.last_match(1)
      url = Regexp.last_match(2)
      bytes, content_type = resolve_image_bytes(url)

      if bytes
        counter += 1
        path = "images/#{post.slug}/body_#{counter}#{extension_for(content_type)}"
        images[path] = bytes
        "![#{alt}](#{path})"
      else
        "![#{alt}](#{url})"
      end
    end

    [ body, images ]
  end

  def resolve_image_bytes(url)
    if (match = url.match(DATA_URI))
      [ Base64.decode64(match[2]), match[1] ]
    elsif (signed_id = url[BLOB_SIGNED_ID, 1])
      blob = ActiveStorage::Blob.find_signed(signed_id)
      blob ? [ blob.download, blob.content_type ] : [ nil, nil ]
    else
      [ nil, nil ]
    end
  end

  def extension_for(content_type)
    EXTENSIONS.fetch(content_type, ".bin")
  end
end
