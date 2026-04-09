# spec/factories/event_types.rb
FactoryBot.define do
  factory :event_type do
    sequence(:name) { |n| "EventType #{n}" }
    description     { Faker::Lorem.paragraph }
    sequence(:icon) { |n| "icon-#{n}" }
  end
end
