# app/models/person_social_media_account.rb
class PersonSocialMediaAccount < ApplicationRecord
  belongs_to :person
  belongs_to :social_media_platform

  validates :username, presence: true
  validates :social_media_platform_id, uniqueness: { scope: :person_id }
end
