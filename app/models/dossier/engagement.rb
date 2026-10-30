# app/models/dossier/engagement.rb

# Who employed or contracted you: employer (or agency), employment type and
# position title. A permanent job gets one Assignment automatically, with the
# employer as client, kept in step with the Engagement's dates.
class Dossier::Engagement < ApplicationRecord
  include Classifiable
  include Dossier::Dated

  belongs_to :employer, class_name: "Dossier::Organisation"
  belongs_to :employment_type
  has_many   :assignments, dependent: :destroy

  normalizes :position_title, with: ->(value) { value.strip }
  normalizes :summary, with: ->(value) { value.strip.presence }

  validates :position_title, presence: true
  validate  :assignments_fit_within_dates, on: :update

  after_create :create_permanent_assignment
  after_update :sync_permanent_assignment

  scope :kept, -> { where(deleted_at: nil) }

  def permanent?
    employment_type&.permanent?
  end

  def soft_delete!
    update_columns(deleted_at: Time.current)
  end

  def restore!
    update_columns(deleted_at: nil)
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
                        end_on: end_on, end_precision: end_precision)
  end

  def sync_permanent_assignment
    synced_assignment&.update!(client: employer, start_on: start_on, start_precision: start_precision,
                               end_on: end_on, end_precision: end_precision)
  end
end
