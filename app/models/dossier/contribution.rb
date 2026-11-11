# app/models/dossier/contribution.rb

# Something you gave rather than received: a talk, workshop, article, podcast,
# a meetup you organised, open-source work or mentoring. Each has a kind, a
# title, the event or publication it was for (an Organisation), a date (a
# day, month or year: start_on, with end_on kept the same), and optionally a
# location, a link, the title you were billed under (presented_as), a
# description, Skills and files such as the poster or slides (owner and
# admins only). It belongs to no Engagement or Assignment; "During" can say
# which Engagement you made it in, for context. Deleting is soft;
# PurgeDeletedDossierContributionsJob removes it after
# DELETION_RETENTION_PERIOD.
class Dossier::Contribution < ApplicationRecord
  include Classifiable
  include Dossier::Dated
  include Dossier::SkillTags

  DELETION_RETENTION_PERIOD = 30.days

  # kind => [label, plural]
  KINDS = {
    "talk" => %w[Talk Talks], "workshop" => %w[Workshop Workshops], "panel" => [ "Panel", "Panels" ],
    "article" => %w[Article Articles], "podcast" => %w[Podcast Podcasts],
    "meetup_organised" => [ "Meetup Organised", "Meetups Organised" ],
    "open_source" => [ "Open Source", "Open Source" ], "mentoring" => %w[Mentoring Mentoring]
  }.freeze

  FILE_TYPES = %w[application/pdf image/jpeg image/png image/webp image/avif].freeze

  self.year_precision = true

  belongs_to :user
  belongs_to :event, class_name: "Dossier::Organisation", optional: true
  belongs_to :engagement, optional: true
  has_many :contribution_skills, -> { order(:id) }, dependent: :destroy, autosave: true, inverse_of: :contribution
  has_many :skills, through: :contribution_skills
  skill_tags :contribution_skills
  has_many_attached :files

  normalizes :title, with: ->(value) { value.strip }
  normalizes :location, :url, :presented_as, :description, with: ->(value) { value.strip.presence }

  # One date: the end is the start, so it's never "current".
  before_validation { self.end_on, self.end_precision = start_on, start_precision }

  validates :title, presence: true
  validates :kind, inclusion: { in: KINDS.keys }
  validates :url, format: Dossier::Credential::URL_FORMAT, allow_nil: true
  validates :files, content_type: { in: FILE_TYPES, message: "must be a PDF, JPEG, PNG, WebP or AVIF" },
                    size: { less_than: 10.megabytes, message: "must be smaller than 10 MB each" }
  validate  :engagement_is_users

  scope :kept,      -> { where(deleted_at: nil) }
  scope :discarded, -> { where.not(deleted_at: nil) }

  def kind_label  = KINDS.dig(kind, 0)
  def kind_plural = KINDS.dig(kind, 1)
  def date        = start_on && formatted_start
  def to_toast_label = title

  def files_visible_to?(user) = user.present? && (user_id == user.id || user.can_administer?)

  def soft_delete! = update_columns(deleted_at: Time.current)
  def restore!     = update_columns(deleted_at: nil)
  def purge_at     = deleted_at && deleted_at + DELETION_RETENTION_PERIOD

  private

  def engagement_is_users
    errors.add(:engagement, "must be one of your Engagements") if engagement && engagement.user_id != user_id
  end
end
