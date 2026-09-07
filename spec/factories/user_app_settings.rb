FactoryBot.define do
  factory :user_app_setting do
    association :user
    app_name { "event_tracker" }
  end
end
