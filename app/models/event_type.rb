# app/models/event_type.rb
class EventType < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :history ]

  LUCIDE_VALID_ICONS = LucideRails::IconProvider.memory.keys.to_set.freeze
  
  has_many :events, dependent: :restrict_with_error

  validates :name,        presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true
  validates :icon,        presence: true, uniqueness: true

  def should_generate_new_friendly_id?
    name_changed? || super
  end
end
