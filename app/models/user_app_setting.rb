# app/models/user_app_setting.rb
class UserAppSetting < ApplicationRecord
  belongs_to :user

  DISPLAY_NAMES = {
    "event_tracker" => "Occasions",
    "blog_posts"    => "Chronicle"
  }.freeze

  # Apps with a real, user-visible landing page today — Recipes/Photo Albums are enum
  # placeholders only (see CLAUDE.md), so they're excluded until they actually ship.
  LIVE_APPS = %w[event_tracker blog_posts].freeze

  enum :app_name, {
    event_tracker: "event_tracker",
    blog_posts:    "blog_posts",
    recipes:       "recipes",
    photo_albums:  "photo_albums"
  }, validate: true

  enum :default_classification, {
    restricted:   "restricted",
    contacts:     "contacts",
    unrestricted: "unrestricted"
  }, validate: true

  validates :app_name, presence: true, uniqueness: { scope: :user_id }

  def self.display_name_for(app_name)
    DISPLAY_NAMES.fetch(app_name.to_s, app_name.to_s.humanize)
  end

  # [["Chronicle", "blog_posts"], ["Occasions", "event_tracker"]] — sorted alphabetically
  # by display name, for use in Start Page dropdowns.
  def self.live_apps_by_display_name
    LIVE_APPS.map { |app_name| [ display_name_for(app_name), app_name ] }.sort_by(&:first)
  end
end
