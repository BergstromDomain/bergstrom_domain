FactoryBot.define do
  factory :person do
    sequence(:firstname) { |n| "Person#{n}" }
    lastname { "Example" }
    middlename { nil }
    description { "Example person description." }
    thumbnail_image { "example_thumb.jpg" }
    full_image { "example.jpg" }
  end
end