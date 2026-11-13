# app/models/dossier/engagement.rb

# Who employed or contracted you: employer (or agency), employment type and
# position title. A permanent job gets one Assignment automatically, with the
# employer as client, kept in step with the Engagement's dates. Deleting is
# soft and hides its Assignments and their Achievements too (assignments are
# the kept ones; a deleted Assignment is restored on its own);
# PurgeDeletedDossierEngagementsJob removes it after DELETION_RETENTION_PERIOD.
class Dossier::Engagement < ApplicationRecord
  include Classifiable
  include Dossier::Dated
  include Dossier::CvSelectable

  DELETION_RETENTION_PERIOD = 30.days

  belongs_to :employer, class_name: "Dossier::Organisation"
  belongs_to :employment_type
  # Deleted Assignments go too, so all_assignments does the destroying.
  has_many   :all_assignments, class_name: "Dossier::Assignment", dependent: :destroy
  has_many   :assignments, -> { kept.in_order }, inverse_of: :engagement
  has_many   :credentials, dependent: :destroy
  # Made during it, for context only: they stay if it goes.
  has_many   :contributions, dependent: :nullify
  # Consultants you worked with during it, though on no shared Assignment.
  has_many   :colleagues, -> { joins(:person).order(*Dossier::ContactDetails::ORDER, "dossier_engagement_colleagues.id") },
             class_name: "Dossier::EngagementColleague", inverse_of: :engagement, dependent: :delete_all

  normalizes :position_title, with: ->(value) { value.strip }
  normalizes :summary, with: ->(value) { value.strip.presence }

  validates :position_title, presence: true
  validate  :assignments_fit_within_dates, on: :update

  after_create :create_permanent_assignment
  after_update :sync_permanent_assignment

  scope :kept,      -> { where(deleted_at: nil) }
  scope :discarded, -> { where.not(deleted_at: nil) }

  def permanent?
    employment_type&.permanent?
  end

  def personal?
    employment_type&.personal? || false
  end

  # Its Colleagues are the owner's and Admins' alone, whatever its classification.
  def private_details_visible_to?(user) = user.present? && (user_id == user.id || user.can_administer?)

  def soft_delete!
    update_columns(deleted_at: Time.current)
  end

  def restore!
    update_columns(deleted_at: nil)
  end

  def purge_at
    deleted_at + DELETION_RETENTION_PERIOD if deleted_at
  end

  def to_toast_label
    "#{position_title} at #{employer&.name}"
  end

  private

  # A permanent job's single Assignment moves with the Engagement, so it's
  # left out of the fit check.
  def synced_assignment
    assignments.first if permanent? && assignments.size == 1
  end

  def assignments_fit_within_dates
    others = assignments.reject { |a| a == synced_assignment }
    return if others.all? { |a| a.fits_within?(self) }

    errors.add(:base, "Every Assignment must fall within the Engagement's dates")
  end

  def create_permanent_assignment
    return unless permanent?

    assignments.create!(client: employer, start_on: start_on, start_precision: start_precision,
                        end_on: end_on, end_precision: end_precision, **Dossier::TechStack::ALL_NA)
  end

  def sync_permanent_assignment
    synced_assignment&.update!(client: employer, start_on: start_on, start_precision: start_precision,
                               end_on: end_on, end_precision: end_precision)
  end
end
