FactoryBot.define do
  factory :guide_page do
    sequence(:title) { |n| "Guide Page #{n}" }
    app_section { "core" }
    body { Faker::Lorem.paragraph }
  end
end
