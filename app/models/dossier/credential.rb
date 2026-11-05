# app/models/dossier/credential.rb

# A degree, certification, course… of a Credential Type, issued by an
# Organisation (the provider, labelled "Issued By"), with Started/Completed
# dates (no Completed yet means in progress), an optional expiry, certificate
# number and verification URL, hours, Skills and a description. Credentials of
# a training type are "Training". A Credential can sit under an Engagement, and
# one of its Assignments, or stand alone (bench time, gaps). It's hidden while
# its Engagement is deleted and purged with it.
class Dossier::Credential < ApplicationRecord
  include Classifiable
  include Dossier::Dated
  include Dossier::SkillTags

  URL_FORMAT = { with: %r{\Ahttps?://\S+\z}i, message: "must start with http:// or https://" }.freeze

  dated_edge :expires

  belongs_to :user
  belongs_to :credential_type
  belongs_to :provider,   class_name: "Dossier::Organisation", optional: true
  belongs_to :engagement, optional: true
  belongs_to :assignment, optional: true
  has_many :credential_skills, -> { order(:id) }, dependent: :destroy, autosave: true, inverse_of: :credential
  has_many :skills, through: :credential_skills
  skill_tags :credential_skills

  normalizes :title, with: ->(value) { value.strip }
  normalizes :description, with: ->(value) { value.strip.presence }
  normalizes :certificate_number, :verification_url, with: ->(value) { value.strip.presence }

  # An Assignment implies its Engagement.
  before_validation { self.engagement = assignment.engagement if assignment }

  validates :title, presence: true
  validates :verification_url, format: URL_FORMAT, allow_nil: true
  validates :hours, numericality: { greater_than: 0 }, allow_nil: true
  validate  :links_belong_to_user
  validate  :expires_after_start

  delegate :training?, to: :credential_type, allow_nil: true

  scope :training, -> { joins(:credential_type).where(dossier_credential_types: { training: true }) }
  # Not under a deleted Engagement.
  scope :kept, -> { left_joins(:engagement).where(dossier_engagements: { deleted_at: nil }) }

  def hidden?
    engagement&.deleted_at.present?
  end

  def to_toast_label = title

  # Like date_range, but an unfinished course is "Mar 2024 – in progress".
  def dates = current? ? "#{formatted_start} – in progress" : date_range

  def formatted_expiry = expires_on && format_dossier_date(expires_on, expires_precision)

  private

  def expires_after_start
    return if expires_on.nil? || start_on.nil?

    errors.add(:expires_month, "must not be before the start") if expires_on < start_on
  end

  def links_belong_to_user
    errors.add(:engagement, "must be one of your Engagements") if engagement && engagement.user_id != user_id
  end
end
