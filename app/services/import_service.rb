# app/services/import_service.rb
require "csv"

class ImportService
  HEADERS = ExportService::HEADERS

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

  def import_row!(row)
    first_name      = row["First name"].to_s.strip
    last_name       = row["Last name"].to_s.strip
    event_type_name = row["Event type"].to_s.strip
    event_title     = row["Event title"].to_s.strip
    date_string     = row["Event date"].to_s.strip

    event_type = EventType.find_by("LOWER(name) = ?", event_type_name.downcase)
    raise ImportRowError, "Unknown event type '#{event_type_name}'" if event_type.nil?

    person = find_or_initialize_person(first_name, last_name)
    person.user ||= @user
    person.save! unless person.persisted?

    event = Event.find_by("LOWER(title) = ?", event_title.downcase)

    if event
      event.people << person unless event.people.include?(person)
    else
      day, month, year = parse_date(date_string)

      event = Event.new(
        title:          event_title,
        event_type:     event_type,
        user:           @user,
        day:            day,
        month:          month,
        year:           year,
        classification: :restricted
      )
      event.people << person
      event.save!
    end
  rescue ActiveRecord::RecordInvalid => e
    raise ImportRowError, e.record.errors.full_messages.to_sentence
  end

  def find_or_initialize_person(first_name, last_name)
    full_name = [ first_name, last_name ].reject(&:blank?).join(" ")
    existing  = Person.all.find { |p| p.full_name.casecmp?(full_name) }
    return existing if existing

    Person.new(first_name: first_name, last_name: last_name, user: @user, classification: :restricted)
  end

  def parse_date(date_string)
    parts = date_string.to_s.split("-", -1)
    raise ImportRowError, "Invalid date '#{date_string}'" unless parts.length == 3

    year_part, month_part, day_part = parts
    year  = year_part.present? ? Integer(year_part, 10) : nil
    month = Integer(month_part, 10)
    day   = Integer(day_part, 10)
    [ day, month, year ]
  rescue ArgumentError
    raise ImportRowError, "Invalid date '#{date_string}'"
  end
end
