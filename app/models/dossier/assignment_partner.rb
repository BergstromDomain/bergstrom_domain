# app/models/dossier/assignment_partner.rb

# An Organisation on an Assignment besides its Client: a Vendor (built part
# of it, e.g. PwC developing the software Deloitte tests) or a Customer (buys
# or uses the result, e.g. Telstra). An optional scope says what they did.
# Private to the owner and Admins (Assignment#private_details_visible_to?)
# and never on a CV.
class Dossier::AssignmentPartner < ApplicationRecord
  KINDS = { "vendor" => "Vendor", "customer" => "Customer" }.freeze

  enum :kind, KINDS.keys.index_by(&:itself)

  belongs_to :assignment
  belongs_to :organisation, class_name: "Dossier::Organisation"

  normalizes :scope, with: ->(value) { value.strip.presence }

  validates :organisation_id, uniqueness: { scope: %i[assignment_id kind], message: ->(partner, _) {
    "is already a #{partner.kind_label} on this Assignment"
  } }

  scope :by_name, -> { joins(:organisation).order(Arel.sql("LOWER(dossier_organisations.name)")) }

  def kind_label = KINDS.fetch(kind)

  def to_toast_label = organisation&.name
end
