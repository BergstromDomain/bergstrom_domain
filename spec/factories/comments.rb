# spec/factories/comments.rb
FactoryBot.define do
  factory :comment do
    association :commentable, factory: :blog_post
    association :user
    body { "A comment." }
  end
end
