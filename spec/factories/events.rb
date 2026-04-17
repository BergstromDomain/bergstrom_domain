# spec/factories/events.rb
FactoryBot.define do
  factory :event do
    association      :event_type
    association      :user
    sequence(:title) { |n| "Event #{n}" }
    description      { Faker::Lorem.paragraph }
    day              { rand(1..28) }
    month            { rand(1..12) }
    year             { [ rand(1950..2025), nil ].sample }
    classification   { "contacts" }
    after(:build) do |event|
      event.people << build(:person) if event.people.empty?
    end
    trait :no_year do
      year { nil }
    end
    trait :dated do
      year { rand(1950..2025) }
    end
    trait :unrestricted do
      classification { "unrestricted" }
    end
    trait :contacts do
      classification { "contacts" }
    end
    trait :restricted do
      classification { "restricted" }
    end
    trait :with_image do
      after(:create) do |event|
        event.image.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename:     "test_event_image.jpg",
          content_type: "image/jpeg"
        )
      end
    end
    trait :with_thumbnail do
      after(:create) do |event|
        event.thumbnail_image.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename:     "test_event_thumbnail.jpg",
          content_type: "image/jpeg"
        )
      end
    end
    trait :with_images do
      after(:create) do |event|
        event.image.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename:     "test_event_image.jpg",
          content_type: "image/jpeg"
        )
        event.thumbnail_image.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename:     "test_event_thumbnail.jpg",
          content_type: "image/jpeg"
        )
      end
    end
  end
end
