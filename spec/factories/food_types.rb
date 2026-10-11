# spec/factories/food_types.rb
FactoryBot.define do
  factory :food_type do
    sequence(:name) { |n| "FoodType #{n}" }
    description     { Faker::Lorem.paragraph }
    sequence(:icon) { |n| FoodType::LUCIDE_VALID_ICONS.to_a[n % FoodType::LUCIDE_VALID_ICONS.size] }
  end
end
