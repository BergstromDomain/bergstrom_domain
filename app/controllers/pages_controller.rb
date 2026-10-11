# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  include Navigable
  skip_before_action :set_left_nav, except: %i[ event_tracker chronicle cookbook user_guide ]

  allow_unauthenticated_access only: %i[ home about contact chronicle cookbook event_tracker user_guide ]

  def home
  end

  def about
  end

  def contact
  end

  def chronicle
  end

  def cookbook
  end

  def settings
  end

  def event_tracker
  end

  # Retrofitted from a static stub into a redirect to the guide directory —
  # there's no single "core" page to land on now that app_section is a
  # category (many pages can share it), not a 1-page-per-app slot. See
  # docs/context-prompts/active/Feature_-_User_Guide.md.
  def user_guide
    redirect_to guide_pages_path
  end
end
