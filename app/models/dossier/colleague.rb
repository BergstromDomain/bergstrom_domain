# app/models/dossier/colleague.rb

# Someone you worked with on an Assignment: name, and optionally position,
# mobile, email, LinkedIn and a comment. Private to the Assignment's owner
# and Admins (Assignment#private_details_visible_to?), whatever the
# Assignment's classification, and never on a CV.
class Dossier::Colleague < ApplicationRecord
  belongs_to :assignment

  normalizes :name, with: ->(value) { value.strip }
  normalizes :position, :mobile, :email, :linkedin_url, :comment, with: ->(value) { value.strip.presence }

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :linkedin_url, format: Dossier::Profile::URL_FORMAT, allow_nil: true

  def to_toast_label = name
end
