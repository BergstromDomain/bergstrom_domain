# app/models/cuisine.rb
class Cuisine < ApplicationRecord
  include Flaggable
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :history ]

  has_many :recipes, dependent: :restrict_with_error

  validates :name,        presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true

  def should_generate_new_friendly_id?
    name_changed? || super
  end

  # Identifying label used by Toastable — see docs/context-prompts/active/New_Feature_Toasts.md
  def to_toast_label
    name
  end
end
