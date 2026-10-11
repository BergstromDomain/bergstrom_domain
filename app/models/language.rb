# app/models/language.rb
class Language < ApplicationRecord
  include Flaggable
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :history ]

  has_many :recipes, dependent: :restrict_with_error

  normalizes :code, with: ->(code) { code.strip.downcase }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  # ISO 639-1 style ("sv", "en") — not checked against the ISO list itself.
  validates :code, presence: true, uniqueness: true
  validates :code, format: { with: /\A[a-z]{2}\z/, message: "must be two letters, e.g. sv" }, allow_blank: true

  def should_generate_new_friendly_id?
    name_changed? || super
  end

  # Identifying label used by Toastable — see docs/context-prompts/active/New_Feature_Toasts.md
  def to_toast_label
    name
  end
end
