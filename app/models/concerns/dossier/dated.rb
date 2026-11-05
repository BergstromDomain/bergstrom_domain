# app/models/concerns/dossier/dated.rb

# A start/end date pair where each date is either exact ("day") or known only
# to the month ("month", stored as the 1st). Code sets them through
# start_month/start_day and end_month/end_day ("2019-03" + optional "15");
# forms send the year and month separately (start_year + start_month_number),
# which make up start_month. No end means current. Month-precision ends count
# as the whole month. A model can add more dates the same way with
# dated_edge (e.g. a Credential's expiry). A model that sets year_precision
# also takes a year on its own ("2001", stored as 1 Jan, lasting the year).
module Dossier
  module Dated
    extend ActiveSupport::Concern

    PRECISIONS = %w[day month].freeze
    MONTH_FORMAT = /\A(\d{4})-(\d{2})\z/
    YEAR_FORMAT = /\A\d{4}\z/

    included do
      class_attribute :year_precision, default: false

      dated_edge :start
      dated_edge :end
      validate :dates_are_valid

      scope :newest_first, -> { order(Arel.sql("#{table_name}.end_on DESC NULLS FIRST, #{table_name}.start_on DESC")) }
    end

    class_methods do
      # Adds the start_month/start_day-style accessors for one more date on
      # the record, e.g. a Credential's expires_on + expires_precision.
      def dated_edge(edge)
        validates :"#{edge}_precision", inclusion: { in: ->(record) { record.class.precisions } }

        define_method(:"#{edge}_month") do
          date_input(edge).fetch(:month) do
            public_send(:"#{edge}_on")&.strftime(public_send(:"#{edge}_precision") == "year" ? "%Y" : "%Y-%m")
          end
        end

        define_method(:"#{edge}_day") do
          date_input(edge).fetch(:day) { public_send(:"#{edge}_on")&.day&.to_s if public_send(:"#{edge}_precision") == "day" }.presence
        end

        define_method(:"#{edge}_month=") do |value|
          date_input(edge).except!(:year, :month_number)
          set_date_input(edge, :month, value.to_s.strip)
        end
        define_method(:"#{edge}_day=")   { |value| set_date_input(edge, :day,   value.to_s.strip) }

        define_method(:"#{edge}_year")         { date_input(edge).fetch(:year) { month_part(edge, 1) } }
        define_method(:"#{edge}_month_number") do
          date_input(edge).fetch(:month_number) { month_part(edge, 2) }&.delete_prefix("0")
        end

        define_method(:"#{edge}_year=")         { |value| set_month_part(edge, :year, value) }
        define_method(:"#{edge}_month_number=") { |value| set_month_part(edge, :month_number, value) }
      end
    end

    class_methods do
      def precisions = year_precision ? PRECISIONS + %w[year] : PRECISIONS
    end

    def current?
      end_on.nil?
    end

    def effective_end
      return if end_on.nil?

      last_day(end_on, end_precision)
    end

    def formatted_start = format_dossier_date(start_on, start_precision)
    def formatted_end   = end_on ? format_dossier_date(end_on, end_precision) : "Present"

    # A range within one month (or day) shows it once: "Jul 2025".
    def date_range
      formatted_start == formatted_end ? formatted_start : "#{formatted_start} – #{formatted_end}"
    end

    private

    def format_dossier_date(date, precision)
      date.strftime({ "day" => "%-d %b %Y", "year" => "%Y" }.fetch(precision, "%b %Y"))
    end

    # The last day a date covers: a month-precision date lasts the month, a
    # year-precision one the year.
    def last_day(date, precision)
      { "month" => date.end_of_month, "year" => date.end_of_year }.fetch(precision, date)
    end

    def date_input(edge)
      (@date_input ||= {})[edge] ||= {}
    end

    def set_date_input(edge, part, value)
      date_input(edge)[part] = value
      apply_date_input(edge)
    end

    def month_part(edge, index)
      month = public_send(:"#{edge}_month").to_s
      return month if index == 1 && month.match?(YEAR_FORMAT)

      month[MONTH_FORMAT, index]
    end

    # Year and month together make up the month; both empty means no date.
    def set_month_part(edge, part, value)
      date_input(edge)[:year] = public_send(:"#{edge}_year").to_s
      date_input(edge)[:month_number] = public_send(:"#{edge}_month_number").to_s
      date_input(edge)[part] = value.to_s.strip
      year, number = date_input(edge).values_at(:year, :month_number)
      month = if number.empty? then year
      else "#{year}-#{number.rjust(2, '0')}"
      end
      set_date_input(edge, :month, month)
    end

    def apply_date_input(edge)
      month, day = public_send(:"#{edge}_month"), public_send(:"#{edge}_day")
      (@bad_date ||= {}).delete(edge)

      if month.blank?
        self[:"#{edge}_on"] = nil
        self[:"#{edge}_precision"] = "month"
      elsif year_precision && month.match?(YEAR_FORMAT)
        self[:"#{edge}_on"] = Date.new(month.to_i, 1, 1)
        self[:"#{edge}_precision"] = "year"
      elsif (match = MONTH_FORMAT.match(month)) && Date.valid_date?(match[1].to_i, match[2].to_i, 1)
        year, month_number = match[1].to_i, match[2].to_i
        if day.present? && Date.valid_date?(year, month_number, day.to_i)
          self[:"#{edge}_on"] = Date.new(year, month_number, day.to_i)
          self[:"#{edge}_precision"] = "day"
        else
          @bad_date[edge] = :day if day.present?
          self[:"#{edge}_on"] = Date.new(year, month_number, 1)
          self[:"#{edge}_precision"] = "month"
        end
      else
        @bad_date[edge] = :month
        self[:"#{edge}_on"] = nil
      end
    end

    def dates_are_valid
      (@bad_date || {}).each do |edge, part|
        message = part == :day ? "is not a day in that month" : "needs a four-digit year and a month, e.g. 2019 and May"
        errors.add(:"#{edge}_#{part}", message)
      end
      errors.add(:start_month, :blank) if start_on.nil? && @bad_date&.dig(:start).nil?
      return if start_on.nil? || end_on.nil?

      errors.add(:end_month, "must not be before the start") if effective_end < start_on
    end
  end
end
