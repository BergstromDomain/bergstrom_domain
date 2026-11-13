# app/models/dossier/organisation.rb

# An employer, client, education provider, credential issuer or a Skill's
# vendor — which of these it is follows from where it's used, so one record
# can be all of them. Its optional logo is a JPEG, PNG or WebP (no SVG: no
# variants, and it can carry scripts); remove_logo = "1" removes it on save.
class Dossier::Organisation < ApplicationRecord
  include Dossier::NamedReferenceData

  belongs_to :industry, optional: true
  has_many :engagements, class_name: "Dossier::Engagement", foreign_key: :employer_id,
                         dependent: :restrict_with_error, inverse_of: :employer
  has_many :client_assignments, class_name: "Dossier::Assignment", foreign_key: :client_id,
                                dependent: :restrict_with_error, inverse_of: :client
  has_many :provided_credentials, class_name: "Dossier::Credential", foreign_key: :provider_id,
                                  dependent: :restrict_with_error, inverse_of: :provider
  # The meetup, conference or publication of someone's Contributions.
  has_many :contributions, class_name: "Dossier::Contribution", foreign_key: :event_id,
                           dependent: :restrict_with_error, inverse_of: :event
  # Vendor or Customer on someone's Assignment (private links).
  has_many :assignment_partners, class_name: "Dossier::AssignmentPartner",
                                 dependent: :restrict_with_error, inverse_of: :organisation
  # The Skills it makes (Microsoft → Project, Excel): public, unlike the
  # private Vendor links above.
  has_many :products, -> { order(Arel.sql("LOWER(dossier_skills.name)")) }, class_name: "Dossier::Skill",
                      foreign_key: :vendor_id, dependent: :restrict_with_error, inverse_of: :vendor

  LOGO_TYPES = %w[image/jpeg image/png image/webp].freeze

  has_one_attached :logo do |attachable|
    attachable.variant :thumbnail, resize_to_limit: [ 160, 160 ]
  end

  attribute :remove_logo, :boolean, default: false
  after_save { logo.purge_later if remove_logo && logo.attached? && !attachment_changes.key?("logo") }

  normalizes :abbreviation, :website_url, with: ->(value) { value.strip.presence }

  validates :abbreviation, length: { maximum: 15 }
  validates :logo, content_type: { in: LOGO_TYPES, spoofing_protection: true, message: "must be a JPEG, PNG or WebP" },
                   size: { less_than: 2.megabytes, message: "must be smaller than 2 MB" }
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
