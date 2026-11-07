# app/services/guide_page_retirer.rb

# Deletes User Guide pages whose Markdown files have been removed.
# GuidePageLoader only ever creates and updates, so a page dropped from
# docs/user-guide would otherwise linger in every database it was loaded
# into. Its title goes in docs/user-guide/retired.yml (a YAML list), and
# `bin/rails guide_pages:retire` deletes it, in dev and in PROD alike.
#
# Titles match ignoring case, like the loader. A title that still has a
# Markdown file is refused, so a live page can't be retired by mistake.
# All-or-nothing, and safe to run again: a page that's already gone is
# reported as absent.
class GuidePageRetirer
  class Error < StandardError; end

  LIST = "retired.yml"

  def initialize(root)
    @root = Pathname.new(root)
  end

  # Returns { removed: [titles], absent: [titles] }.
  def call
    titles = retired_titles
    refuse_live_pages(titles)

    result = { removed: [], absent: [] }
    GuidePage.transaction do
      titles.each do |title|
        page = GuidePage.find_by("LOWER(title) = ?", title.downcase)
        page ? result[:removed] << page.destroy!.title : result[:absent] << title
      end
    end
    result
  end

  private

  def retired_titles
    list = @root.join(LIST)
    return [] unless list.file?

    titles = YAML.safe_load(list.read) || []
    raise Error, "#{LIST} must be a list of titles" unless titles.is_a?(Array) && titles.all?(String)

    titles
  end

  def refuse_live_pages(titles)
    live = live_files
    clashes = titles.filter_map { |title| (file = live[title.downcase]) && "#{title} (#{file})" }
    raise Error, "Still has a Markdown file, so can't be retired: #{clashes.join(', ')}" if clashes.any?
  end

  # Lowercased title => file, for every guide page in docs/user-guide.
  def live_files
    @root.glob("*/*.md").to_h do |file|
      front_matter = GuidePageLoader::FRONT_MATTER.match(file.read)
      title = front_matter && (YAML.safe_load(front_matter[:yaml]) || {})["title"]
      [ title.to_s.downcase, file.relative_path_from(@root).to_s ]
    end
  end
end
