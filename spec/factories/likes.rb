# spec/factories/likes.rb
FactoryBot.define do
  factory :like do
    association :blog_post
    association :user
    face { "neutral" }
  end
end
