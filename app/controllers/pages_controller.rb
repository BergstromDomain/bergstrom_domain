# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  allow_unauthenticated_access

  def home; end
  def about; end
  def contact; end
end
