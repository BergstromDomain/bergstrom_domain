# app/models/event_mute.rb
class EventMute < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :event_id, uniqueness: { scope: :user_id }
end
