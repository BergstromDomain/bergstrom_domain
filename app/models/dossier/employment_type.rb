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
end
