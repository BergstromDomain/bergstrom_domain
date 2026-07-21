# app/models/person_mute.rb
class PersonMute < ApplicationRecord
  belongs_to :user
  belongs_to :person

  validates :person_id, uniqueness: { scope: :user_id }
end
