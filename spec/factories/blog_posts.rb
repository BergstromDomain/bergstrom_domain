# spec/factories/blog_posts.rb
FactoryBot.define do
  factory :blog_post do
    association      :user
    sequence(:title) { |n| "Blog Post #{n}" }
    body             { Faker::Lorem.paragraph }
    classification   { "contacts" }

    trait :unrestricted do
      classification { "unrestricted" }
    end

    trait :contacts do
      classification { "contacts" }
    end

    trait :restricted do
      classification { "restricted" }
    end

    trait :published do
      published_at { Time.current }
    end

    trait :raw do
      format { "raw" }
    end
  end
end
