# spec/factories/ingredient_sections.rb
FactoryBot.define do
  factory :ingredient_section do
    association :recipe
    heading     { "Meat sauce" }
    sequence(:position) { |n| n }
  end
end
