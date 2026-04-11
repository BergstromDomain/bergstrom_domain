# spec/factories/events.rb
FactoryBot.define do
  factory :event do
    association      :event_type
    sequence(:title) { |n| "Event #{n}" }
    description      { Faker::Lorem.paragraph }
    day              { rand(1..28) }
    month            { rand(1..12) }
    year             { [ rand(1950..2025), nil ].sample }
    image            { nil }
    thumbnail_image  { nil }

    after(:build) do |event|
      event.people << build(:person) if event.people.empty?
    end

    trait :no_year do
      year { nil }
    end

    trait :dated do
      year { rand(1950..2025) }
    end

    trait :with_images do
      image           { "events/cover.jpg" }
      thumbnail_image { "events/thumb.jpg" }
    end
  end
end
