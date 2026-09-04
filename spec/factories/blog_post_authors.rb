# spec/factories/blog_post_authors.rb
FactoryBot.define do
  factory :blog_post_author do
    association :blog_post
    association :user
  end
end
