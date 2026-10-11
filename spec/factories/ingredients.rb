# spec/factories/ingredients.rb
FactoryBot.define do
  factory :ingredient do
    association :ingredient_section
    quantity    { "2" }
    measurement { "dl" }
    name        { "milk" }
    sequence(:position) { |n| n }
  end
end
