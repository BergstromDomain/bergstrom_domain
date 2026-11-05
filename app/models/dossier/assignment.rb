# app/models/dossier/assignment.rb

# Where the work was done: client, project, role, dates and location, within
# its Engagement's dates. user_id mirrors the Engagement's owner (for Policy and
# Classifiable). With no Role, the Engagement's position title stands in.
class Dossier::Assignment < ApplicationRecord
  include Classifiable
  include Dossier::Dated
  include Dossier::TechStack
  include Dossier::CvSelectable

  belongs_to :engagement
  belongs_to :client,   class_name: "Dossier::Organisation"
  belongs_to :role,     optional: true
  belongs_to :location, optional: true
  # Deleted Achievements go too, so all_achievements does the destroying.
  has_many   :all_achievements, class_name: "Dossier::Achievement", dependent: :destroy
  has_many   :achievements, -> { kept.in_order }, inverse_of: :assignment
  # Its Training stays with the Engagement.
  has_many   :credentials, dependent: :nullify

  normalizes :summary, :project, with: ->(value) { value.strip.presence }

  before_validation { self.user_id = engagement&.user_id }

  validate :fits_within_engagement

  def role_name
    role&.name || engagement&.position_title
  end

  # "Client - Project" (just the client without one), to tell one client's
  # Assignments apart.
  def heading
    [ client&.short_name, project ].compact.join(" - ")
  end

  def fits_within?(outer)
    start_on >= outer.start_on && (outer.end_on.nil? || (end_on && effective_end <= outer.effective_end))
  end

  # An Assignment is deleted with its Engagement (it has no soft delete of its
  # own), so Policy hides it from everyone but Admins until it's restored.
  def deleted_at
    engagement&.deleted_at
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
