# app/services/person_event_filter.rb

# Jql-based filter over the same "one row per person+event combination" shape
# ExportService/ImportService's CSV already uses (a person-only row, with a
# nil event, when they have no visible events) — mirrors BlogPostFilter, but
# for a synthetic row instead of a single model, since Occasions has no
# single "the resource" the way Chronicle has BlogPost.
class PersonEventFilter
  Row = Struct.new(:person, :event, keyword_init: true)

  FIELD_SCHEMA = {
    first_name: :string,
    last_name:  :string,
    event_type: :string,
    title:      :string,
    date:       :date
  }.freeze

  EVALUATOR = Jql::Evaluator.new(FIELD_SCHEMA)

  def self.attributes_for(row)
    {
      first_name: row.person.first_name,
      last_name:  row.person.last_name,
      event_type: row.event&.event_type&.name,
      title:      row.event&.title,
      date:       row.event && event_date(row.event)
    }
  end

  def self.event_date(event)
    return nil unless event.year && event.month && event.day

    Date.new(event.year, event.month, event.day)
  rescue Date::Error
    nil
  end

  # Builds an AND of whichever filters are present; returns nil ("no filter,
  # show everything") when every argument is blank.
  def self.basic_ast(first_name: nil, last_name: nil, event_type: nil, title: nil, date_range: nil)
    conditions = []
    conditions << string_comparison(:first_name, first_name) if first_name.present?
    conditions << string_comparison(:last_name, last_name) if last_name.present?
    conditions << string_comparison(:event_type, event_type) if event_type.present?
    conditions << string_comparison(:title, title) if title.present?

    if date_range
      conditions << date_comparison(:date, ">=", date_range.first)
      conditions << date_comparison(:date, "<=", date_range.last)
    end

    conditions.reduce { |left, right| Jql::Parser::And.new(left: left, right: right) }
  end

  # Nils sort last regardless of direction.
  def self.sort(rows, column, direction)
    column = column.to_sym
    values = rows.to_h { |row| [ row, attributes_for(row)[column] ] }
    with_nil, without_nil = rows.partition { |row| values[row].nil? }

    sorted = without_nil.sort_by { |row| sort_key(values[row]) }
    sorted.reverse! if direction == "desc"
    sorted + with_nil
  end

  def self.string_comparison(field, value)
    Jql::Parser::Comparison.new(field: field, operator: "=", value: value, value_type: :string)
  end
  private_class_method :string_comparison

  def self.date_comparison(field, operator, date)
    Jql::Parser::Comparison.new(field: field, operator: operator, value: date.iso8601, value_type: :string)
  end
  private_class_method :date_comparison

  def self.sort_key(value)
    value.is_a?(String) ? value.downcase : value
  end
  private_class_method :sort_key
end
