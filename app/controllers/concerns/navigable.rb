# app/controllers/concerns/navigable.rb
module Navigable
  extend ActiveSupport::Concern

  included do
    before_action :set_left_nav
  end

  private

  def set_left_nav
    @show_left_nav = true
    @left_nav_section = left_nav_section_for(controller_name, action_name)
  end

  def left_nav_section_for(controller, action)
    return :blog_posts if controller == "pages" && action == "chronicle"

    case controller
    when "events", "event_types", "people", "pages"
      :event_tracker
    when "settings", "contacts"
      :settings
    when "blog_posts", "blog_categories", "blog_exports"
      :blog_posts
    end
  end
end
