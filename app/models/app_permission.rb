# app/models/app_permission.rb
class AppPermission < ApplicationRecord
  belongs_to :user

  enum :app_name, {
    event_tracker: "event_tracker",
    blog_posts:    "blog_posts",
    recipes:       "recipes",
    photo_albums:  "photo_albums"
  }, validate: true

  validates :app_name, presence: true
  validates :app_name, uniqueness: { scope: :user_id }
end
