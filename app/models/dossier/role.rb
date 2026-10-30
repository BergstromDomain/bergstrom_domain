# app/models/dossier/role.rb
class Dossier::Role < ApplicationRecord
  include Dossier::NamedReferenceData

  has_many :assignments, dependent: :restrict_with_error
end
