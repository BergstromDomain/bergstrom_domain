# app/models/dossier/assignment.rb

# Where the work was done: client, project, role, dates and location, within
# its Engagement's dates. user_id mirrors the Engagement's owner (for Policy and
# Classifiable). With no Role, the Engagement's position title stands in.
# Deleting is soft and hides its Achievements and Training too, like an
# Engagement's; PurgeDeletedDossierAssignmentsJob removes it after
# DELETION_RETENTION_PERIOD.
class Dossier::Assignment < ApplicationRecord
  include Classifiable
  include Dossier::Dated
  include Dossier::TechStack
  include Dossier::CvSelectable

  DELETION_RETENTION_PERIOD = 30.days

  belongs_to :engagement
  belongs_to :client,   class_name: "Dossier::Organisation"
  belongs_to :role,     optional: true
  belongs_to :location, optional: true
  # Deleted Achievements go too, so all_achievements does the destroying.
  has_many   :all_achievements, class_name: "Dossier::Achievement", dependent: :destroy
  has_many   :achievements, -> { kept.in_order }, inverse_of: :assignment
  # Its Training stays with the Engagement.
  has_many   :credentials, dependent: :nullify
  # Private details (Block 12): only the owner and Admins see them.
  has_many   :colleagues, -> { order(Arel.sql("LOWER(dossier_colleagues.name)"), :id) }, dependent: :delete_all
  has_many   :partners, class_name: "Dossier::AssignmentPartner", dependent: :delete_all
  has_many   :vendors,   -> { vendor.by_name.includes(:staff_members) },   class_name: "Dossier::AssignmentPartner"
  has_many   :customers, -> { customer.by_name.includes(:staff_members) }, class_name: "Dossier::AssignmentPartner"

  normalizes :summary, :project, with: ->(value) { value.strip.presence }

  before_validation { self.user_id = engagement&.user_id }

  validate :fits_within_engagement

  scope :kept,      -> { where(deleted_at: nil) }
  scope :discarded, -> { where.not(deleted_at: nil) }

  def role_name
    role&.name || engagement&.position_title
  end

  # "Client - Project" (just the client without one), to tell one client's
  # Assignments apart.
  def heading
    [ client&.short_name, project ].compact.join(" - ")
  end

  # "APA Group - Energy Components Upgrade": the page title, with the client's
  # full name.
  def title
    [ client&.name, project ].compact.join(" - ")
  end

  # Colleagues, Vendors and Customers: the owner and Admins only, whatever
  # the classification, and never on a CV.
  def private_details_visible_to?(user) = user.present? && (user_id == user.id || user.can_administer?)

  def fits_within?(outer)
    start_on >= outer.start_on && (outer.end_on.nil? || (end_on && effective_end <= outer.effective_end))
  end

  def soft_delete!
    update_columns(deleted_at: Time.current)
  end

  def restore!
    update_columns(deleted_at: nil)
  end

  def purge_at
    deleted_at + DELETION_RETENTION_PERIOD if deleted_at
  end

  # Deleted itself, or with its Engagement: Policy hides it from everyone but
  # Admins until it's restored.
  def hidden?
    deleted_at.present? || engagement&.deleted_at.present?
  end

  def to_toast_label
    "#{role_name} at #{client&.name}"
  end

  private

  def fits_within_engagement
    return if engagement.nil? || start_on.nil? || engagement.start_on.nil?

    if start_on < engagement.start_on
      errors.add(:start_month, "must not be before the Engagement starts (#{engagement.formatted_start})")
    end
    return if engagement.end_on.nil? || (end_on && effective_end <= engagement.effective_end)

    errors.add(:end_month, "must not be after the Engagement ends (#{engagement.formatted_end})")
  end
end
