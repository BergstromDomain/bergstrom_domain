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

  # The Show page warns this long before a Credential expires.
  EXPIRY_WARNING_PERIOD = 90

  # Certificate scans: shown only to the owner and admins, whatever the
  # classification (they can carry personal details).
  FILE_TYPES = %w[application/pdf image/jpeg image/png].freeze

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
  has_many_attached :files

  normalizes :title, with: ->(value) { value.strip }
  normalizes :description, with: ->(value) { value.strip.presence }
  normalizes :certificate_number, :verification_url, with: ->(value) { value.strip.presence }

  # An Assignment implies its Engagement.
  before_validation { self.engagement = assignment.engagement if assignment }

  validates :title, presence: true
  validates :verification_url, format: URL_FORMAT, allow_nil: true
  validates :files, content_type: { in: FILE_TYPES, message: "must be a PDF, JPEG or PNG" },
                    size: { less_than: 10.megabytes, message: "must be smaller than 10 MB each" }
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

  def files_visible_to?(user) = user.present? && (user_id == user.id || user.can_administer?)

  # Like date_range, but an unfinished course is "Mar 2024 – in progress".
  def dates = current? ? "#{formatted_start} – in progress" : date_range

  def formatted_expiry = expires_on && format_dossier_date(expires_on, expires_precision)

  # The last day it's valid: a month-precision expiry lasts the whole month.
  def expires_at_end = expires_on && (expires_precision == "month" ? expires_on.end_of_month : expires_on)

  def expired?(today = Date.current) = expires_on.present? && expires_at_end < today

  def days_until_expiry(today = Date.current) = expires_on && (expires_at_end - today).to_i

  def expiring_soon?(today = Date.current)
    expires_on.present? && !expired?(today) && days_until_expiry(today) <= EXPIRY_WARNING_PERIOD
  end

  # The Show page's Warning toast; nil when it's not expired or expiring soon.
  def expiry_warning(today = Date.current)
    preposition = expires_precision == "day" ? "on" : "in"
    if expired?(today)
      "This Credential expired #{preposition} #{formatted_expiry}."
    elsif expiring_soon?(today)
      days = days_until_expiry(today)
      return "This Credential expires today, #{formatted_expiry}." if days.zero?

      "This Credential expires #{preposition} #{formatted_expiry}, in #{days} #{'day'.pluralize(days)}."
    end
  end

  private

  def expires_after_start
    return if expires_on.nil? || start_on.nil?

    errors.add(:expires_month, "must not be before the start") if expires_on < start_on
  end

  def links_belong_to_user
    errors.add(:engagement, "must be one of your Engagements") if engagement && engagement.user_id != user_id
  end
end
