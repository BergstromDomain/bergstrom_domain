# spec/factories/cuisines.rb
FactoryBot.define do
  factory :cuisine do
    sequence(:name) { |n| "Cuisine #{n}" }
    description     { Faker::Lorem.paragraph }
    flag            { "🇸🇪" }
  end
end
