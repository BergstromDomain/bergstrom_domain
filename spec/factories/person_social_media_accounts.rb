FactoryBot.define do
  factory :person_social_media_account do
    association :person
    association :social_media_platform
    sequence(:username) { |n| "handle_#{n}" }
  end
end
