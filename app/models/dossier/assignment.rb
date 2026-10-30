# app/models/dossier/assignment.rb

# Where the work was done: client, role, dates and location, within its
# Engagement's dates. user_id mirrors the Engagement's owner (for Policy and
# Classifiable). With no Role, the Engagement's position title stands in.
class Dossier::Assignment < ApplicationRecord
  include Classifiable
  include Dossier::Dated
  include Dossier::TechStack

  belongs_to :engagement
  belongs_to :client,   class_name: "Dossier::Organisation"
  belongs_to :role,     optional: true
  belongs_to :location, optional: true

  normalizes :summary, with: ->(value) { value.strip.presence }

  before_validation { self.user_id = engagement&.user_id }

  validate :fits_within_engagement

  def role_name
    role&.name || engagement&.position_title
  end

  def fits_within?(outer)
    start_on >= outer.start_on && (outer.end_on.nil? || (end_on && effective_end <= outer.effective_end))
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
