# app/models/dossier/employment_type.rb
class Dossier::EmploymentType < ApplicationRecord
  include Dossier::NamedReferenceData

  has_many :engagements, dependent: :restrict_with_error

  # A permanent Engagement auto-creates its one Assignment (client = employer);
  # flagged here rather than inferred from the name, which admins can change.
  validates :permanent, inclusion: { in: [ true, false ] }
end
