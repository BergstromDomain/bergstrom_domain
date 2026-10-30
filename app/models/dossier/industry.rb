# app/models/dossier/industry.rb
class Dossier::Industry < ApplicationRecord
  include Dossier::NamedReferenceData

  has_many :organisations, dependent: :restrict_with_error
end
