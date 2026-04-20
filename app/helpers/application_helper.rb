# app/helpers/application_helper.rb
module ApplicationHelper
  # Returns true for Content Creator and above — controls Actions and
  # Import & Export section visibility in the left nav.
  def can_see_left_nav_actions?
    current_user&.content_creator? || current_user&.admin? || current_user&.system_admin?
  end

  # Returns the correct CSS class string for a left nav link,
  # applying the active modifier when ctrl matches the current controller.
  def left_nav_link_class(ctrl)
    base = "left-nav-link"
    controller_name == ctrl ? "#{base} left-nav-link--active" : base
  end
end
