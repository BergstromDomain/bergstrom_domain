# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  include Navigable
  skip_before_action :set_left_nav, except: %i[ event_tracker import_export user_guide ]

  allow_unauthenticated_access only: %i[ home about contact blog_posts event_tracker user_guide ]

  def home
  end

  def about
  end

  def contact
  end

  def blog_posts
  end

  def settings
  end

  def event_tracker
  end

  def import_export
  end

  def user_guide
  end
end
