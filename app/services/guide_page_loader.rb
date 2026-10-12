# app/services/guide_page_loader.rb

# Loads User Guide pages from version-controlled Markdown files
# (docs/user-guide/<app>/*.md) into GuidePage rows, so the same text goes into
# dev and PROD and is reviewed in a PR. Each file starts with YAML front
# matter (title, app_section, supports_* flags) between "---" lines; the rest
# is the Markdown body. Pages match on title, ignoring case, so a re-run
# updates rather than duplicates. All-or-nothing: one bad file saves nothing.
# Run via `bin/rails guide_pages:load[cookbook]`.
class GuidePageLoader
  class Error < StandardError; end

  FRONT_MATTER = /\A---\s*\n(?<yaml>.*?)\n---\s*\n(?<body>.*)\z/m
  FLAGS = GuidePage::SUPPORT_COLUMNS.keys.map(&:to_s).freeze

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
      body:        match[:body].strip,
      **FLAGS.index_with { |flag| attributes.fetch(flag, false) }
    )
    page
  rescue Psych::SyntaxError => e
    raise Error, "#{file.basename}: #{e.message}"
  end

  def save!(page, file)
    return if page.save

    raise Error, "#{file.basename}: #{page.errors.full_messages.to_sentence}"
  end
end
