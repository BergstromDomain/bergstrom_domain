# spec/factories/app_permissions.rb
FactoryBot.define do
  factory :app_permission do
    association :user
    app_name    { "event_tracker" }
    can_create  { false }
    can_update  { false }
    can_delete  { false }

    trait :with_create do
      can_create { true }
    end

    trait :with_update do
      can_update { true }
    end

    trait :with_delete do
      can_delete { true }
    end

    trait :full_access do
      can_create { true }
      can_update { true }
      can_delete { true }
    end
  end
end
