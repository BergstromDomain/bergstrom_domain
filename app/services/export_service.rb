# app/services/export_service.rb
require "csv"

class ExportService
  HEADERS = [ "First name", "Last name", "Event type", "Event title", "Event date" ].freeze

  def initialize(user, scopes)
    @user   = user
    @scopes = scopes
  end

  def generate_csv
    CSV.generate(headers: true, encoding: "UTF-8") do |csv|
      csv << HEADERS

      people_in_scope.each do |person|
        events = events_for_person(person)

        if events.empty?
          csv << [ person.first_name, person.last_name, nil, nil, nil ]
        else
          events.each do |event|
            csv << [
              person.first_name,
              person.last_name,
              event.event_type&.name,
              event.title,
              format_date(event)
            ]
          end
        end
      end
    end
  end

  private

  def people_in_scope
    Person.where(user: scoped_users, classification: scoped_classifications)
          .order("LOWER(last_name), LOWER(first_name)")
  end

  def events_for_person(person)
    person.events
          .where(classification: scoped_classifications)
          .includes(:event_type)
          .order("year ASC NULLS LAST, month ASC, day ASC")
  end

  def scoped_users
    if @scopes.include?(:unrestricted) && (@scopes & %i[restricted contacts]).empty?
      User.all
    elsif @scopes.include?(:unrestricted)
      [ @user ] + User.all.to_a
    else
      [ @user ]
    end
  end

  def scoped_classifications
    @scopes.map { |s| Event.classifications[s.to_s] }.compact
  end

  def format_date(event)
    return nil unless event.year

    "#{event.year}-#{event.month.to_s.rjust(2, '0')}-#{event.day.to_s.rjust(2, '0')}"
  end
end
