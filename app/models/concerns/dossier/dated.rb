# app/models/concerns/dossier/dated.rb

# A start/end date pair where each date is either exact ("day") or known only
# to the month ("month", stored as the 1st). Forms set them through
# start_month/start_day and end_month/end_day ("2019-03" + optional "15");
# no end means current. Month-precision ends count as the whole month.
module Dossier
  module Dated
    extend ActiveSupport::Concern

    PRECISIONS = %w[day month].freeze
    MONTH_FORMAT = /\A(\d{4})-(\d{2})\z/

    included do
      validates :start_precision, :end_precision, inclusion: { in: PRECISIONS }
      validate :dates_are_valid

      scope :newest_first, -> { order(Arel.sql("#{table_name}.end_on DESC NULLS FIRST, #{table_name}.start_on DESC")) }
    end

    %i[start end].each do |edge|
      define_method(:"#{edge}_month") { date_input(edge).fetch(:month) { public_send(:"#{edge}_on")&.strftime("%Y-%m") } }

      define_method(:"#{edge}_day") do
        date_input(edge).fetch(:day) { public_send(:"#{edge}_on")&.day&.to_s if public_send(:"#{edge}_precision") == "day" }.presence
      end

      define_method(:"#{edge}_month=") { |value| set_date_input(edge, :month, value.to_s.strip) }
      define_method(:"#{edge}_day=")   { |value| set_date_input(edge, :day,   value.to_s.strip) }
    end

    def current?
      end_on.nil?
    end

    def effective_end
      return if end_on.nil?

      end_precision == "month" ? end_on.end_of_month : end_on
    end

    def formatted_start = format_dossier_date(start_on, start_precision)
    def formatted_end   = end_on ? format_dossier_date(end_on, end_precision) : "Present"

    def date_range
      "#{formatted_start} – #{formatted_end}"
    end

    private

    def format_dossier_date(date, precision)
      date.strftime(precision == "day" ? "%-d %b %Y" : "%b %Y")
    end

    def date_input(edge)
      (@date_input ||= {})[edge] ||= {}
    end

    def set_date_input(edge, part, value)
      date_input(edge)[part] = value
      apply_date_input(edge)
    end

    def apply_date_input(edge)
      month, day = public_send(:"#{edge}_month"), public_send(:"#{edge}_day")
      (@bad_date ||= {}).delete(edge)

      if month.blank?
        self[:"#{edge}_on"] = nil
        self[:"#{edge}_precision"] = "month"
      elsif (match = MONTH_FORMAT.match(month))
        year, month_number = match[1].to_i, match[2].to_i
        if day.present? && Date.valid_date?(year, month_number, day.to_i)
          self[:"#{edge}_on"] = Date.new(year, month_number, day.to_i)
          self[:"#{edge}_precision"] = "day"
        else
          @bad_date[edge] = :day if day.present?
          self[:"#{edge}_on"] = Date.valid_date?(year, month_number, 1) ? Date.new(year, month_number, 1) : nil
          self[:"#{edge}_precision"] = "month"
        end
      else
        @bad_date[edge] = :month
        self[:"#{edge}_on"] = nil
      end
    end

    def dates_are_valid
      (@bad_date || {}).each do |edge, part|
        message = part == :day ? "is not a day in that month" : "is not a valid month"
        errors.add(:"#{edge}_#{part}", message)
      end
      errors.add(:start_month, :blank) if start_on.nil? && @bad_date&.dig(:start).nil?
      return if start_on.nil? || end_on.nil?

      errors.add(:end_month, "must not be before the start") if effective_end < start_on
    end
  end
end
