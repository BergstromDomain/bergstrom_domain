# spec/factories/person_mutes.rb
FactoryBot.define do
  factory :person_mute do
    association :user
    association :person
  end
end
