# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:first_name) { |n| "First#{n}" }
    sequence(:last_name)  { |n| "Last#{n}" }
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password              { "password123" }
    password_confirmation { "password123" }
    role                  { "app_user" }
    status                { "active" }

    trait :content_creator do
      role { "content_creator" }
    end

    trait :admin do
      role { "admin" }
    end

    trait :system_admin do
      role { "system_admin" }
    end

    trait :pending do
      status { "pending" }
    end

    trait :suspended do
      status { "suspended" }
    end
  end
end
