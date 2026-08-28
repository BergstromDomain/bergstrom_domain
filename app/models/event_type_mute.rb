# app/models/event_type_mute.rb
class EventTypeMute < ApplicationRecord
  belongs_to :user
  belongs_to :event_type

  validates :event_type_id, uniqueness: { scope: :user_id }
end
