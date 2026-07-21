# spec/factories/event_mutes.rb
FactoryBot.define do
  factory :event_mute do
    association :user
    association :event
  end
end
