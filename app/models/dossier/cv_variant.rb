# app/models/dossier/cv_variant.rb

# A tailored CV ("QE Lead — Acme, Oct 2026") picked from the master data: a
# voice, a style, an optional summary override (the only text a variant has
# of its own, Q-D7), whether to show each Assignment's Tech Stack, and the
# minimum importance of the Achievements it includes by default. Items tick
# or untick single records; everything else follows Dossier::CvSelection's
# default rules. Copy From starts a variant from another one.
class Dossier::CvVariant < ApplicationRecord
  include Classifiable

  VOICES = { "first_person" => "First Person", "implied" => "Implied", "third_person" => "Third Person" }.freeze
  STYLES = { "classic" => "Classic" }.freeze
  COPIED_ATTRIBUTES = %w[target_company target_role job_description voice style summary_override
                         show_tech_stack min_importance].freeze

  belongs_to :based_on, class_name: "Dossier::CvVariant", optional: true
  has_many :items, class_name: "Dossier::CvVariantItem", dependent: :delete_all, inverse_of: :cv_variant

  normalizes :name, with: ->(value) { value.strip }
  normalizes :target_company, :target_role, :job_description, :summary_override, with: ->(value) { value.strip.presence }

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :voice, inclusion: { in: VOICES.keys }
  validates :style, inclusion: { in: STYLES.keys }
  validates :min_importance, inclusion: { in: Dossier::Achievement::IMPORTANCE }
  validate  :based_on_belongs_to_user

  scope :alphabetical, -> { order(Arel.sql("LOWER(name)")) }

  # An unsaved variant with another's settings and item rows.
  def self.copy_from(original, **attributes)
    new(user: original.user, based_on: original, **original.slice(*COPIED_ATTRIBUTES), **attributes).tap do |copy|
      original.items.each { |item| copy.items.build(item: item.item, included: item.included) }
    end
  end

  def summary
    summary_override || user.dossier_profile&.summary_for(voice)
  end

  def voice_label = VOICES.fetch(voice)
  def style_label = STYLES.fetch(style)

  def to_toast_label = name

  private

  def based_on_belongs_to_user
    errors.add(:based_on, "must be one of your CV Variants") if based_on && based_on.user_id != user_id
  end
end
