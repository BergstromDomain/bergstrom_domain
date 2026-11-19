# app/models/dossier/employment_type.rb
class Dossier::EmploymentType < ApplicationRecord
  include Dossier::NamedReferenceData

  has_many :engagements, dependent: :restrict_with_error

  # A permanent Engagement auto-creates its one Assignment (client = employer);
  # flagged here rather than inferred from the name, which admins can change.
  validates :permanent, inclusion: { in: [ true, false ] }

  # A personal Engagement (a hobby project) counts as personal experience,
  # never professional, and the Timeline leaves it out of gaps and bench time.
  validates :personal, inclusion: { in: [ true, false ] }

  # A career break (time off, looking for work): its Engagements need no
  # Employer, have no Assignments, count towards no experience and stay off
  # the CV. The Timeline shows them but, like personal ones, never as filling a gap.
  validates :career_break, inclusion: { in: [ true, false ] }
  validate  :career_break_alone

  private

  def career_break_alone
    return unless career_break

    errors.add(:career_break, "can't be both a career break and permanent") if permanent
    errors.add(:career_break, "can't be both a career break and personal") if personal
  end
end
