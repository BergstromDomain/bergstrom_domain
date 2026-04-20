# app/controllers/concerns/navigable.rb
module Navigable
  extend ActiveSupport::Concern

  included do
    before_action :set_left_nav
  end

  private

  def set_left_nav
    @show_left_nav = true
    @left_nav_section = left_nav_section_for(controller_name)
  end

  def left_nav_section_for(controller)
    case controller
    when "events", "event_types", "people"
      :event_tracker
    end
  end
end
