# app/models/event.rb
class Event < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]

  # ── Associations  ────────────────────────────────────────────────────────
  belongs_to :event_type

  # ── Validations ──────────────────────────────────────────────────────────
  validates :title,       presence: true, uniqueness: { case_sensitive: false }
  validates :day,   presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 31 }
  validates :month, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :year,        numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # ── Scope ────────────────────────────────────────────────────────────────
  scope :chronological,    -> { order(:year, :month, :day) }
  scope :reverse_chrono,   -> { order(Arel.sql("year DESC NULLS LAST, month DESC, day DESC")) }

  # ── Instance methods ──────────────────────────────────────────────────────
  def display_date
    month_name = Date::ABBR_MONTHNAMES[month]
    year? ? "#{day} #{month_name} #{year}" : "#{day} #{month_name}"
  end

  def should_generate_new_friendly_id?
    title_changed? || super
  end
end
