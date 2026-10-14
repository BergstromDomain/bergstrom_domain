# app/services/guide_page_loader.rb

# Loads User Guide pages from version-controlled Markdown files
# (docs/user-guide/<app>/*.md) into GuidePage rows, so the same text goes into
# dev and PROD and is reviewed in a PR. Each file starts with YAML front
# matter (title, app_section, supports_* flags) between "---" lines; the rest
# is the Markdown body. Pages match on title, ignoring case, so a re-run
# updates rather than duplicates. All-or-nothing: one bad file saves nothing.
# Run via `bin/rails guide_pages:load[cookbook]`.
#
# Screenshots sit in the folder's images/ subfolder and are written
# `![Alt text](images/name.png)`, so they also preview on GitHub. Loading
# points them at the guide image route (GuideImagesController), after
# checking each one exists and has alt text.
class GuidePageLoader
  class Error < StandardError; end

  FRONT_MATTER = /\A---\s*\n(?<yaml>.*?)\n---\s*\n(?<body>.*)\z/m
  FLAGS = GuidePage::SUPPORT_COLUMNS.keys.map(&:to_s).freeze
  IMAGE = %r{!\[(?<alt>[^\]]*)\]\(images/(?<name>[^)]+)\.png\)}
  IMAGE_NAME = /\A[a-z0-9_-]+\z/

  def initialize(directory)
    @directory = Pathname.new(directory)
  end

  # Returns { created: [titles], updated: [titles], unchanged: [titles] }.
  def call
    raise Error, "No guide page directory at #{@directory}" unless @directory.directory?

    result = { created: [], updated: [], unchanged: [] }
    GuidePage.transaction do
      @directory.glob("*.md").sort.each do |file|
        page = load_file(file)
        status = page.new_record? ? :created : (page.changed? ? :updated : :unchanged)
        save!(page, file) unless status == :unchanged
        result[status] << page.title
      end
    end
    result
  end

  private

  def load_file(file)
    match = FRONT_MATTER.match(file.read)
    raise Error, "#{file.basename}: missing the --- front matter block" unless match

    attributes = YAML.safe_load(match[:yaml]) || {}
    page = GuidePage.where("LOWER(title) = ?", attributes["title"].to_s.downcase).first || GuidePage.new
    page.assign_attributes(
      title:       attributes["title"],
      app_section: attributes["app_section"],
      body:        link_images(match[:body].strip, file),
      **FLAGS.index_with { |flag| attributes.fetch(flag, false) }
    )
    page
  rescue Psych::SyntaxError => e
    raise Error, "#{file.basename}: #{e.message}"
  end

  def link_images(body, file)
    body.gsub(IMAGE) do
      alt, name = $~[:alt], $~[:name]
      image = "images/#{name}.png"
      raise Error, "#{file.basename}: #{image} needs alt text" if alt.blank?
      raise Error, "#{file.basename}: #{image} — use lowercase letters, digits, - and _ in image names" unless name.match?(IMAGE_NAME)
      raise Error, "#{file.basename}: #{image} isn't in #{@directory.join('images')}" unless @directory.join(image).file?

      "![#{alt}](#{Rails.application.routes.url_helpers.guide_image_path(app: @directory.basename.to_s, name: name)})"
    end
  end

  def save!(page, file)
    return if page.save

    raise Error, "#{file.basename}: #{page.errors.full_messages.to_sentence}"
  end
end
