# app/services/blog_post_import_service.rb
require "csv"

class BlogPostImportService
  HEADERS = [ "Title", "Category", "Subject", "Topic", "Body (Markdown)" ].freeze

  Result = Struct.new(:imported_count, :failed_count, :errors, keyword_init: true)

  class ImportRowError < StandardError; end

  def initialize(user, file)
    @user = user
    @file = file
  end

  def import
    imported = 0
    failures = []

    rows.each_with_index do |row, index|
      row_number = index + 2 # header is row 1

      begin
        ActiveRecord::Base.transaction do
          import_row!(row)
        end
        imported += 1
      rescue ImportRowError => e
        failures << { row: row_number, message: e.message }
      end
    end

    Result.new(imported_count: imported, failed_count: failures.length, errors: failures)
  end

  private

  def rows
    content = @file.respond_to?(:read) ? @file.read : File.read(@file)
    content = content.force_encoding("UTF-8").gsub(/\r\n?/, "\n")
    CSV.parse(content, headers: true)
  end

  # Imported posts always land as Draft + Restricted — the most conservative
  # state, matching ImportService's own "always import as the most restricted
  # state" precedent — the importing user reviews/edits/publishes afterward.
  def import_row!(row)
    title = row["Title"].to_s.strip
    raise ImportRowError, "Title can't be blank" if title.blank?

    BlogPost.create!(
      user:           @user,
      title:          title,
      blog_category:  find_category(row["Category"]),
      subject:        row["Subject"].to_s.strip.presence,
      topic:          row["Topic"].to_s.strip.presence,
      body:           row["Body (Markdown)"].to_s,
      format:         "raw",
      classification: :restricted
    )
  rescue ActiveRecord::RecordInvalid => e
    raise ImportRowError, e.record.errors.full_messages.to_sentence
  end

  # Unlike EventType (required on Event, so a miss fails the row), a Blog
  # Category is optional on BlogPost — and creating one is admin-only, so an
  # unmatched/blank name leaves the post uncategorized rather than failing.
  def find_category(name)
    name = name.to_s.strip
    return nil if name.blank?

    BlogCategory.find_by("LOWER(name) = ?", name.downcase)
  end
end
