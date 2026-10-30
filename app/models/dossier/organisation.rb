# app/models/dossier/organisation.rb

# An employer, client, education provider or credential issuer — which of
# these it is follows from where it's used, so one record can be all of them.
class Dossier::Organisation < ApplicationRecord
  include Dossier::NamedReferenceData

  belongs_to :industry, optional: true
  has_many :engagements, class_name: "Dossier::Engagement", foreign_key: :employer_id,
                         dependent: :restrict_with_error, inverse_of: :employer
  has_many :client_assignments, class_name: "Dossier::Assignment", foreign_key: :client_id,
                                dependent: :restrict_with_error, inverse_of: :client

  normalizes :abbreviation, :website_url, with: ->(value) { value.strip.presence }

  validates :abbreviation, length: { maximum: 15 }
  validates :website_url, format: { with: %r{\Ahttps?://\S+\z}i, message: "must start with http:// or https://" },
                          allow_nil: true

  # "Full Name (ABBR)" for headings, the abbreviation in running text.
  def label
    abbreviation ? "#{name} (#{abbreviation})" : name
  end

  def short_name
    abbreviation || name
  end
end
