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

    # Publishing needs at least one ingredient, so a published recipe
    # comes with a one-row, unheaded list.
    trait :published do
      published_at { Time.current }

      after(:build) do |recipe|
        next if recipe.ingredient_sections.any?

        recipe.ingredient_sections.build(position: 0)
          .ingredients.build(quantity: "1", name: "onion", position: 0)
      end
    end
  end
end
