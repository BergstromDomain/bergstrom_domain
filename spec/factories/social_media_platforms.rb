FactoryBot.define do
  factory :social_media_platform do
    sequence(:name) { |n| "Platform #{n}" }
    url             { "https://www.example.com/" }
    description     { Faker::Lorem.sentence }
  end
end
