# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  include Navigable
  skip_before_action :set_left_nav, except: %i[ event_tracker chronicle import_export user_guide ]

  allow_unauthenticated_access only: %i[ home about contact chronicle event_tracker user_guide ]

  def home
  end

  def about
  end

  def contact
  end

  def chronicle
  end

  def settings
  end

  def event_tracker
  end

  def import_export
  end

  # Retrofitted from a static stub into a redirect: goes to the "core"
  # GuidePage once an admin has written one, falling back further to the
  # full guide directory (GuidePagesController#index) while it's still
  # unwritten — see docs/context-prompts/active/Feature_-_User_Guide.md.
  def user_guide
    core_page = GuidePage.find_by(app_section: "core")
    redirect_to(core_page ? guide_page_path(core_page) : guide_pages_path)
  end
end
