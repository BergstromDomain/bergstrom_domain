# app/controllers/system_admin/base_controller.rb
module SystemAdmin
  class BaseController < ApplicationController
    before_action :require_system_admin!

    private

    def require_system_admin!
      unless authenticated? && current_user.system_admin?
        redirect_to root_path, alert: "You are not authorised to access that page."
      end
    end
  end
end
