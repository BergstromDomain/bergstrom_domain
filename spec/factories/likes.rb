# spec/factories/likes.rb
FactoryBot.define do
  factory :like do
    association :likeable, factory: :blog_post
    association :user
    face { nil }
  end
end
