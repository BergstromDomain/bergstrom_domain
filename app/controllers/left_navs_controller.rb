# app/controllers/left_navs_controller.rb
class LeftNavsController < ApplicationController
  def toggle_visibility
    Current.session.toggle_left_nav_visibility!
    head :no_content
  end

  def toggle_section
    Current.session.toggle_left_nav_section!(params.require(:key))
    head :no_content
  end
end
