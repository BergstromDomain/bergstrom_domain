# app/models/person.rb
class Person < ApplicationRecord
  include Classifiable

  extend FriendlyId
  friendly_id :full_name, use: [ :slugged, :history ]

  # ── Associations ──────────────────────────────────────────────────────────
  has_many :event_people, dependent: :destroy
  has_many :events, through: :event_people

  has_one_attached :image do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 200, 200 ]
  end

  # ── Validations ──────────────────────────────────────────────────────────
  validates :first_name, presence: true
  validate  :full_name_must_be_unique

  validates :image,
    content_type: { in: %w[image/jpeg image/png image/webp], message: "must be a JPEG, PNG, or WebP" },
    size:         { less_than: 5.megabytes, message: "must be smaller than 5MB" }

  # ── Virtual attribute ─────────────────────────────────────────────────────
  def full_name
    [ first_name, middle_name, last_name ].reject(&:blank?).join(" ")
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
