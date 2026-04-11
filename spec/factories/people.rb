# spec/factories/people.rb
FactoryBot.define do
  factory :person do
    first_name  { Faker::Name.first_name }
    middle_name { [ Faker::Name.first_name, nil ].sample }
    last_name   { Faker::Name.last_name }
    description { Faker::Lorem.paragraph }

    trait :first_name_only do
      middle_name { nil }
      last_name   { nil }
    end

    trait :with_thumbnail do
      after(:create) do |person|
        person.thumbnail_image.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename:     "test_thumbnail.jpg",
          content_type: "image/jpeg"
        )
      end
    end

    trait :with_full_image do
      after(:create) do |person|
        person.full_image.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename:     "test_full_image.jpg",
          content_type: "image/jpeg"
        )
      end
    end

    trait :complete do
      description { Faker::Lorem.paragraph(sentence_count: 3) }
      after(:create) do |person|
        person.thumbnail_image.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename:     "test_thumbnail.jpg",
          content_type: "image/jpeg"
        )
        person.full_image.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename:     "test_full_image.jpg",
          content_type: "image/jpeg"
        )
      end
    end

    trait :james_hetfield do
      first_name  { "James" }
      middle_name { "Alan" }
      last_name   { "Hetfield" }
      description { "Vocalist and rhythm guitarist, co-founder of Metallica." }
    end

    trait :lars_ulrich do
      first_name  { "Lars" }
      middle_name { nil }
      last_name   { "Ulrich" }
      description { "Drummer and co-founder of Metallica." }
    end

    trait :kirk_hammett do
      first_name  { "Kirk" }
      middle_name { "Lee" }
      last_name   { "Hammett" }
      description { "Lead guitarist of Metallica." }
    end

    trait :robert_trujillo do
      first_name  { "Robert" }
      middle_name { "Agustin" }
      last_name   { "Trujillo" }
      description { "Bassist of Metallica." }
    end
  end
end
