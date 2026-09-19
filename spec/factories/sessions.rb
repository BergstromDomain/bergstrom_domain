# spec/factories/sessions.rb
FactoryBot.define do
  factory :session do
    association :user
  end
end
