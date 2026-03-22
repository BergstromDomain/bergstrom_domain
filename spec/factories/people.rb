# spec/factories/people.rb

FactoryBot.define do
  factory :person do
    first_name      { Faker::Name.first_name }
    middle_name     { [ Faker::Name.first_name, nil ].sample }
    last_name       { Faker::Name.last_name }
    description     { Faker::Lorem.paragraph }
    thumbnail_image { nil }
    full_image      { nil }

    trait :first_name_only do
      middle_name { nil }
      last_name   { nil }
    end

    trait :complete do
      description     { Faker::Lorem.paragraph(sentence_count: 3) }
      thumbnail_image { "people/thumbnails/placeholder_thumbnail.png" }
      full_image      { "people/full/placeholder_full.png" }
    end

    trait :james_hetfield do
      first_name      { "James" }
      middle_name     { "Alan" }
      last_name       { "Hetfield" }
      description     { "Vocalist and rhythm guitarist, co-founder of Metallica." }
      thumbnail_image { "people/thumbnails/james_hetfield_thumb.jpg" }
      full_image      { "people/full/james_hetfield.jpg" }
    end

    trait :lars_ulrich do
      first_name      { "Lars" }
      middle_name     { nil }
      last_name       { "Ulrich" }
      description     { "Drummer and co-founder of Metallica." }
      thumbnail_image { "people/thumbnails/lars_ulrich_thumb.jpg" }
      full_image      { "people/full/lars_ulrich.jpg" }
    end

    trait :kirk_hammett do
      first_name      { "Kirk" }
      middle_name     { "Lee" }
      last_name       { "Hammett" }
      description     { "Lead guitarist of Metallica." }
      thumbnail_image { "people/thumbnails/kirk_hammett_thumb.jpg" }
      full_image      { "people/full/kirk_hammett.jpg" }
    end

    trait :robert_trujillo do
      first_name      { "Robert" }
      middle_name     { "Agustin" }
      last_name       { "Trujillo" }
      description     { "Bassist of Metallica." }
      thumbnail_image { "people/thumbnails/robert_trujillo_thumb.jpg" }
      full_image      { "people/full/robert_trujillo.jpg" }
    end
  end
end
