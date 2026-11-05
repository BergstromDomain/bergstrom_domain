# app/models/dossier/credential.rb

# A course, certificate or degree. Block 4.5 starts it slim as Training: a
# course with a provider, dates (no end yet means in progress), hours, Skills
# and a description. A course can sit under an Engagement, and one of its
# Assignments, or stand alone (bench time, gaps). It's hidden while its
# Engagement is deleted and purged with it. Block 5 adds the other types,
# expiry and certificate uploads.
class Dossier::Credential < ApplicationRecord
  include Classifiable
  include Dossier::Dated
  include Dossier::SkillTags

  TYPES = %w[course].freeze

  belongs_to :user
  belongs_to :provider,   class_name: "Dossier::Organisation", optional: true
  belongs_to :engagement, optional: true
  belongs_to :assignment, optional: true
  has_many :credential_skills, -> { order(:id) }, dependent: :destroy, autosave: true, inverse_of: :credential
  has_many :skills, through: :credential_skills
  skill_tags :credential_skills

  normalizes :title, with: ->(value) { value.strip }
  normalizes :description, with: ->(value) { value.strip.presence }

  # An Assignment implies its Engagement.
  before_validation { self.engagement = assignment.engagement if assignment }

  validates :title, presence: true
  validates :credential_type, inclusion: { in: TYPES }
  validates :hours, numericality: { greater_than: 0 }, allow_nil: true
  validate  :links_belong_to_user

  scope :training, -> { where(credential_type: "course") }
  # Not under a deleted Engagement.
  scope :kept, -> { left_joins(:engagement).where(dossier_engagements: { deleted_at: nil }) }

  def hidden?
    engagement&.deleted_at.present?
  end

  def to_toast_label = title

  # Like date_range, but an unfinished course is "Mar 2024 – in progress".
  def dates = current? ? "#{formatted_start} – in progress" : date_range

  private

  def links_belong_to_user
    errors.add(:engagement, "must be one of your Engagements") if engagement && engagement.user_id != user_id
  end
end
