# app/models/concerns/dossier/contact_details.rb

# A private contact — an Assignment's Colleague or a Vendor's/Customer's
# Staff member: a name, and optionally position, mobile, email, LinkedIn and
# a comment. Private to the owner and Admins and never on a CV.
module Dossier::ContactDetails
  extend ActiveSupport::Concern

  FIELDS = %i[name position mobile email linkedin_url comment].freeze

  included do
    normalizes :name, with: ->(value) { value.strip }
    normalizes :position, :mobile, :email, :linkedin_url, :comment, with: ->(value) { value.strip.presence }

    validates :name, presence: true
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
    validates :linkedin_url, format: Dossier::Profile::URL_FORMAT, allow_nil: true
  end

  def to_toast_label = name
end
