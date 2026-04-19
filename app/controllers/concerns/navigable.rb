# app/controllers/concerns/navigable.rb
module Navigable
  extend ActiveSupport::Concern

  included do
    before_action :set_show_left_nav
  end

  private

  def set_show_left_nav
    @show_left_nav = true
  end
end
