# app/models/event.rb
class Event < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]

  # ── Associations  ────────────────────────────────────────────────────────
  belongs_to :event_type
  has_many :event_people, dependent: :destroy
  has_many :people, through: :event_people
  has_one_attached :image
  has_one_attached :thumbnail_image

  # ── Validations ──────────────────────────────────────────────────────────
  validates :title, presence: true, uniqueness: { case_sensitive: false }
  validates :day, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 31 }
  validates :month, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :year, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate  :must_have_at_least_one_person

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

  validates :image,
    content_type: { in: %w[image/jpeg image/png image/webp], message: "must be a JPEG, PNG, or WebP" },
    size:         { less_than: 5.megabytes, message: "must be smaller than 5MB" }

  validates :thumbnail_image,
    content_type: { in: %w[image/jpeg image/png image/webp], message: "must be a JPEG, PNG, or WebP" },
    size:         { less_than: 5.megabytes, message: "must be smaller than 5MB" }

  private

  def must_have_at_least_one_person
    errors.add(:base, "Event must have at least one person") if people.size.zero?
  end
end
