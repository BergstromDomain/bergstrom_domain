# spec/factories/people.rb
FactoryBot.define do
  factory :person do
    association :user
    sequence(:first_name) { |n| "First#{n}" }
    middle_name           { nil }
    sequence(:last_name)  { |n| "Last#{n}" }
    description           { Faker::Lorem.paragraph }
    classification        { "contacts" }

    trait :unrestricted do
      classification { "unrestricted" }
    end

    trait :contacts do
      classification { "contacts" }
    end

    trait :restricted do
      classification { "restricted" }
    end

    trait :first_name_only do
      middle_name { nil }
      last_name   { nil }
    end

    trait :with_image do
      after(:create) do |person|
        person.image.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename:     "test_image.jpg",
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
