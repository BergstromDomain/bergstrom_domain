# app/helpers/blog_posts_helper.rb
module BlogPostsHelper
  FILTER_SORT_LABELS = {
    "category" => "Category",
    "subject"  => "Subject",
    "topic"    => "Topic",
    "title"    => "Blog Title",
    "author"   => "Author",
    "created"  => "Created",
    "smiles"   => "Smiles"
  }.freeze

  # A sortable column header link for the Filter results table — preserves
  # every other current query param (mode/query/category_id/etc.) and
  # toggles direction when the same column is clicked again.
  def filter_sort_link(column)
    next_direction = (@sort == column && @direction == "asc") ? "desc" : "asc"
    query = request.query_parameters.merge("sort" => column, "direction" => next_direction)
    arrow = @sort == column ? (@direction == "asc" ? " ▲" : " ▼") : ""

    link_to "#{FILTER_SORT_LABELS.fetch(column)}#{arrow}", filter_blog_posts_path(query),
      data: { testid: "sort-#{column}" }
  end

  # A plain-text teaser for Browse's cards and Filter's Summary column — strips
  # the rendered Markdown down to plain text (including any syntax-highlighting
  # spans) before truncating, so the preview never shows raw HTML/markup.
  def blog_post_teaser(post)
    strip_tags(post.rendered_body).squish.truncate(200)
  end

  # The PDF template renders in an isolated headless-Chrome page with no
  # browsing context/origin (see PdfRenderingService) — a relative or signed
  # ActiveStorage URL wouldn't resolve, so the header image is inlined as a
  # self-contained base64 data URI instead.
  def blog_image_data_uri(post)
    return nil unless post.blog_image.attached?

    blob = post.blog_image.blob
    "data:#{blob.content_type};base64,#{Base64.strict_encode64(blob.download)}"
  end
end
