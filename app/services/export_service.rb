# app/services/export_service.rb
require "csv"

# Formats already-filtered PersonEventFilter::Row objects as CSV — mirrors
# BlogPostExportService (takes pre-filtered records, not scope symbols).
# Visibility/scoping now happens once, up front, in PeopleEventsFilterable —
# this service has no knowledge of the current user or classification at all.
class ExportService
  HEADERS = [ "First name", "Last name", "Event type", "Event title", "Event date" ].freeze

  def initialize(rows)
    @rows = rows
  end

  def generate_csv
    CSV.generate(headers: true, encoding: "UTF-8") do |csv|
      csv << HEADERS

      @rows.each do |row|
        csv << [
          row.person.first_name,
          row.person.last_name,
          row.event&.event_type&.name,
          row.event&.title,
          row.event && format_date(row.event)
        ]
      end
    end
  end

  private

  def format_date(event)
    return nil unless event.year

    "#{event.year}-#{event.month.to_s.rjust(2, '0')}-#{event.day.to_s.rjust(2, '0')}"
  end
end
