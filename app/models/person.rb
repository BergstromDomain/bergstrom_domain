# app/models/person.rb
class Person < ApplicationRecord
  include Classifiable

  extend FriendlyId
  friendly_id :full_name, use: [ :slugged, :history ]

  # SQL fragment for the A–Z bucketing rule: last_name if present,
  # first_name otherwise. Shared between the scope below and the
  # `available_letters` lookup so the two can never disagree.
  BUCKET_LETTER_SQL = "UPPER(LEFT(COALESCE(NULLIF(last_name, ''), first_name), 1))".freeze

  # Explicit array, not a Range — "Z".succ is "AA", not "Å", so a Range
  # can't be extended to include the three extra Swedish letters.
  BUCKET_LETTERS = ("A".."Z").to_a + %w[Å Ä Ö]

  # ── Associations ──────────────────────────────────────────────────────────
  has_many :event_people, dependent: :destroy
  has_many :events, through: :event_people
  has_many :person_mutes, dependent: :destroy

  has_one_attached :image do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 200, 200 ]
  end

  # ── Validations ──────────────────────────────────────────────────────────
  validates :first_name, presence: true
  validate  :full_name_must_be_unique

  validates :image,
    content_type: { in: %w[image/jpeg image/png image/webp], message: "must be a JPEG, PNG, or WebP" },
    size:         { less_than: 5.megabytes, message: "must be smaller than 5MB" }

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :by_letter, ->(letter) { where("#{BUCKET_LETTER_SQL} = ?", letter.to_s.upcase) }

  # ── Class methods ─────────────────────────────────────────────────────────
  # Distinct set of bucket letters actually present in a given scope —
  # used to decide which A–Z tabs are clickable vs. disabled.
  def self.available_letters(scope = all)
    scope.distinct.pluck(Arel.sql(BUCKET_LETTER_SQL)).compact
  end

  # ── Virtual attribute ─────────────────────────────────────────────────────
  def full_name
    [ first_name, middle_name, last_name ].reject(&:blank?).join(" ")
  end

  def bucket_letter
    (last_name.presence || first_name).to_s.first&.upcase
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  def should_generate_new_friendly_id?
    first_name_changed? || middle_name_changed? || last_name_changed? || super
  end

  private

  def full_name_must_be_unique
    return if first_name.blank?
    scope = Person.where.not(id: id.to_i)
    errors.add(:base, "Full name has already been taken") if scope.any? { |p| p.full_name.casecmp?(full_name) }
  end
end
