FactoryBot.define do
  factory :guide_page do
    sequence(:title) { |n| "Guide Page #{n}" }
    sequence(:app_section) { |n| GuidePage.app_sections.keys[n % GuidePage.app_sections.size] }
    body { Faker::Lorem.paragraph }
  end
end
