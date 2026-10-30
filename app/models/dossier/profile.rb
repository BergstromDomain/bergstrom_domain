# app/models/dossier/profile.rb

# One per user: contact details, headline and summary. The summary is stored
# once in terse form; first- and third-person versions are optional (Q-D6),
# and third_person_name + pronouns are for third-person output.
class Dossier::Profile < ApplicationRecord
  include Classifiable

  URL_FORMAT = { with: %r{\Ahttps?://\S+\z}i, message: "must start with http:// or https://" }.freeze

  PRONOUNS = { "he" => "He/Him", "she" => "She/Her", "they" => "They/Them" }.freeze

  # belongs_to :user comes from Classifiable.
  belongs_to :location, optional: true

  normalizes :display_name, with: ->(value) { value.strip }
  normalizes :headline, :email, :phone, :website_url, :linkedin_url, :github_url,
             :summary, :summary_first_person, :summary_third_person, :third_person_name,
             with: ->(value) { value.strip.presence }

  validates :display_name, presence: true
  validates :user_id, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :website_url, :linkedin_url, :github_url, format: URL_FORMAT, allow_nil: true
  validates :pronouns, inclusion: { in: PRONOUNS.keys }

  # The user's profile, or a new unsaved one started from their name.
  def self.for(user)
    user.dossier_profile || new(user: user,
                                display_name: "#{user.first_name} #{user.last_name}",
                                third_person_name: user.first_name)
  end

  def summary_for(voice)
    case voice.to_sym
    when :first_person then summary_first_person || summary
    when :third_person then summary_third_person || summary
    else summary
    end
  end

  def pronouns_label
    PRONOUNS.fetch(pronouns)
  end

  def to_toast_label
    display_name
  end
end
