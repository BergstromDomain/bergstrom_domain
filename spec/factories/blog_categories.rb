# spec/factories/blog_categories.rb
FactoryBot.define do
  factory :blog_category do
    sequence(:name) { |n| "BlogCategory #{n}" }
    description     { Faker::Lorem.paragraph }
    sequence(:icon) { |n| BlogCategory::LUCIDE_VALID_ICONS.to_a[n % BlogCategory::LUCIDE_VALID_ICONS.size] }
  end
end
