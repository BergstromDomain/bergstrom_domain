# app/models/dossier/location.rb
class Dossier::Location < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :history ]

  has_many :assignments, dependent: :restrict_with_error
  has_many :profiles, dependent: :nullify

  normalizes :city, :country, with: ->(value) { value.strip }

  validates :city,    presence: true
  validates :country, presence: true
  validate  :city_and_country_are_unique

  scope :alphabetical, -> { order(Arel.sql("LOWER(country) ASC, LOWER(city) ASC")) }

  def name
    [ city, country ].compact_blank.join(", ")
  end

  def should_generate_new_friendly_id?
    city_changed? || country_changed? || super
  end

  def to_toast_label
    name
  end

  private

  # Rails' uniqueness validator compares a scope column case-sensitively.
  def city_and_country_are_unique
    return if city.blank? || country.blank?

    duplicate = self.class.where.not(id: id)
                    .exists?([ "LOWER(city) = ? AND LOWER(country) = ?", city.downcase, country.downcase ])
    errors.add(:city, :taken) if duplicate
  end
end
