# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password              { "password123" }
    password_confirmation { "password123" }
    role                  { "app_user" }

    trait :content_creator do
      role { "content_creator" }
    end

    trait :admin do
      role { "admin" }
    end

    trait :system_admin do
      role { "system_admin" }
    end
  end
end
