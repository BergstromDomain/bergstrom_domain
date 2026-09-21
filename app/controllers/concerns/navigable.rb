# app/controllers/concerns/navigable.rb
module Navigable
  extend ActiveSupport::Concern

  included do
    before_action :set_left_nav
  end

  private

  def set_left_nav
    # @show_left_nav means "does this page have a left nav section at all"
    # (also drives the footer's indent, see FooterHelper#footer_class) —
    # always true here, distinct from whether the nav is currently
    # collapsed to its thin restore-only strip, which _left_nav.html.erb
    # reads directly off Current.session.
    @show_left_nav = true
    @left_nav_section = left_nav_section_for(controller_name, action_name)

    # Deliberately re-resumes the session here (same as Authentication#resume_session)
    # rather than trusting Current.session to already be set — controllers that
    # allow_unauthenticated_access run their own resume_session_if_present as a
    # separate before_action, and its registration order relative to this one
    # (set by include Navigable) isn't guaranteed to run first.
    Current.session ||= find_session_by_cookie
    Current.session&.sync_left_nav_section!(@left_nav_section)
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
    when "guide_pages"
      :guide_pages
    end
  end
end
