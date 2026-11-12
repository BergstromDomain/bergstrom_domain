# app/models/concerns/dossier/contact_details.rb

# A private contact — an Assignment's Colleague or a Vendor's/Customer's
# Staff member: a link to a Person (Occasions), who holds the name, Work Email
# and LinkedIn, and optionally their position there and a comment, which
# belong to this Assignment. Private to the owner and Admins and never on a
# CV; the Person is as visible as their own classification lets them be.
module Dossier::ContactDetails
  extend ActiveSupport::Concern

  # The contact's own fields, and the Person's that its form edits.
  FIELDS = %i[position comment].freeze
  PERSON_FIELDS = %i[first_name middle_name last_name work_email linkedin_url].freeze

  # What a contact's own pages show: the Person and their LinkedIn.
  PRELOAD = { person: { person_social_media_accounts: :social_media_platform } }.freeze
  # What a contacts table shows: those and the Person's thumbnail.
  TABLE_PRELOAD = { person: [ { person_social_media_accounts: :social_media_platform }, { image_attachment: :blob } ] }.freeze

  # By the Person's name, as it's shown.
  ORDER = [ Arel.sql("people.first_name"), Arel.sql("people.middle_name NULLS FIRST"), Arel.sql("people.last_name") ].freeze

  included do
    belongs_to :person
    accepts_nested_attributes_for :person, update_only: true

    normalizes :position, :comment, with: ->(value) { value.strip.presence }

    delegate :work_email, :linkedin_url, to: :person, allow_nil: true
  end

  def name = person&.full_name
  def to_toast_label = name
end
