# app/controllers/concerns/navigable.rb
module Navigable
  extend ActiveSupport::Concern

  included do
    before_action :set_left_nav
  end

  private

  def set_left_nav
    @left_nav_section = left_nav_section_for(controller_name, action_name)

    # Deliberately re-resumes the session here (same as Authentication#resume_session)
    # rather than trusting Current.session to already be set — controllers that
    # allow_unauthenticated_access run their own resume_session_if_present as a
    # separate before_action, and its registration order relative to this one
    # (set by include Navigable) isn't guaranteed to run first.
    Current.session ||= find_session_by_cookie

    if Current.session
      Current.session.sync_left_nav_section!(@left_nav_section)
      @show_left_nav = Current.session.left_nav_visible?
    else
      @show_left_nav = true
    end
  end

  def left_nav_section_for(controller, action)
    return :blog_posts if controller == "pages" && action == "chronicle"

    case controller
    when "events", "event_types", "people", "pages", "social_media_platforms"
      :event_tracker
    when "settings", "contacts"
      :settings
    when "blog_posts", "blog_categories", "blog_exports"
      :blog_posts
    end
  end
end
