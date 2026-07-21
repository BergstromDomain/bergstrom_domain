# app/models/event.rb
class Event < ApplicationRecord
  include Classifiable

  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]

  belongs_to :event_type
  has_many :event_people, dependent: :destroy
  has_many :people, through: :event_people
  has_many :event_mutes, dependent: :destroy

  has_one_attached :image do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 200, 200 ]
  end

  before_validation :normalize_title

  validates :title,  presence: true, uniqueness: { case_sensitive: false }
  validates :day,    presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 31 }
  validates :month,  presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :year,   numericality: { only_integer: true, greater_than_or_equal_to: 1000 }, allow_nil: true
  validate  :must_have_at_least_one_person
  validate  :date_must_be_valid

  validates :image,
    content_type: { in: %w[image/jpeg image/png image/webp], message: "must be a JPEG, PNG, or WebP" },
    size:         { less_than: 5.megabytes, message: "must be smaller than 5MB" }

  scope :chronological,  -> { order(:year, :month, :day) }
  scope :reverse_chrono, -> { order(Arel.sql("year DESC NULLS LAST, month DESC, day DESC")) }

  def display_date
    month_name = Date::ABBR_MONTHNAMES[month]
    year? ? "#{day} #{month_name} #{year}" : "#{day} #{month_name}"
  end

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  # Narrows a scope by the user's mute preferences across the three
  # independent, opt-out mute mechanisms (Person, Event, EventType), combined
  # with OR-hide logic: an event is excluded if it is itself muted, its
  # EventType is muted, or every person attached to it is muted. An event
  # with at least one unmuted person stays visible even if some of its
  # people are muted.
  def self.not_muted_for(user)
    muted_event_ids      = EventMute.where(user: user).select(:event_id)
    muted_event_type_ids = EventTypeMute.where(user: user).select(:event_type_id)
    muted_person_ids     = PersonMute.where(user: user).select(:person_id)
    events_with_unmuted_person = EventPerson.where.not(person_id: muted_person_ids).select(:event_id)

    where.not(id: muted_event_ids)
         .where.not(event_type_id: muted_event_type_ids)
         .where(id: events_with_unmuted_person)
  end

  private

  def normalize_title
    self.title = title.squish if title.present?
  end

  def must_have_at_least_one_person
    errors.add(:base, "Event must have at least one person") if people.size.zero?
  end

  def date_must_be_valid
    return unless day.present? && month.present?
    year_to_check = year.present? ? year : 2001
    Date.new(year_to_check, month, day)
  rescue ArgumentError
    errors.add(:base, "Date is not valid")
  end
end
