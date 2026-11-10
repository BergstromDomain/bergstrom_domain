# app/models/dossier/credential_type.rb

# What kind of Credential it is: Degree, Certification, Course… Admin-managed
# reference data (Q-D9). Position orders the groups on Credentials › Credentials;
# a training type (Course, Workshop) shows in the Training panels on Engagement
# and Assignment pages and on Skill pages.
class Dossier::CredentialType < ApplicationRecord
  include Dossier::NamedReferenceData

  has_many :credentials, dependent: :restrict_with_error

  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :training, inclusion: { in: [ true, false ] }

  scope :in_order, -> { order(:position).merge(alphabetical) }
end
