# spec/factories/comments.rb
FactoryBot.define do
  factory :comment do
    association :blog_post
    association :user
    body { "A comment." }
  end
end
