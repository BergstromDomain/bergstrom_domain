# spec/factories/recipes.rb
FactoryBot.define do
  factory :recipe do
    association      :user
    association      :cuisine
    association      :food_type
    association      :language
    sequence(:title) { |n| "Recipe #{n}" }
    body             { Faker::Lorem.paragraph }
    classification   { "contacts" }

    trait :unrestricted do
      classification { "unrestricted" }
    end

    trait :contacts do
      classification { "contacts" }
    end

    trait :restricted do
      classification { "restricted" }
    end

    trait :published do
      published_at { Time.current }
    end
  end
end
