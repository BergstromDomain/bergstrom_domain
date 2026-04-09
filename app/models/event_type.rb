# app/models/event_type.rb
class EventType < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :history ]

  # ── Validations ──────────────────────────────────────────────────────────
  validates :name,        presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true
  validates :icon,        presence: true, uniqueness: true

  # ── FriendlyId ───────────────────────────────────────────────────────────
  def should_generate_new_friendly_id?
    name_changed? || super
  end
end
