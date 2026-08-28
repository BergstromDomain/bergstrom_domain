# spec/factories/event_type_mutes.rb
FactoryBot.define do
  factory :event_type_mute do
    association :user
    association :event_type
  end
end
