# app/models/person.rb
class Person < ApplicationRecord
  extend FriendlyId
  friendly_id :full_name, use: [ :slugged, :history ]

  # ── Validations ──────────────────────────────────────────────────────────
  validates :first_name, presence: true
  validate  :full_name_must_be_unique

  # ── Virtual attribute ─────────────────────────────────────────────────────
  def full_name
    [ first_name, middle_name, last_name ].reject(&:blank?).join(" ")
  end

  # ── FriendlyId ───────────────────────────────────────────────────────────
  def should_generate_new_friendly_id?
    first_name_changed? || middle_name_changed? || last_name_changed? || super
  end

  private

  def full_name_must_be_unique
    return if first_name.blank?

    scope = Person.where(
      first_name:  first_name.strip,
      middle_name: middle_name.presence,
      last_name:   last_name.presence
    )

    scope = scope.where.not(id: id) if persisted?

    if scope.exists?
      errors.add(:base, "Full name has already been taken")
    end
  end
end
