# spec/factories/contacts.rb
FactoryBot.define do
  factory :contact do
    association :user
    association :contact, factory: :user
    status { "pending" }
  end
end
