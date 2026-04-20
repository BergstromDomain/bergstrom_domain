# app/models/policy.rb
class Policy
  def initialize(user, resource)
    @user     = user
    @resource = resource
  end

  def can_read?
    return false unless @resource.respond_to?(:classification)

    case @resource.classification
    when "unrestricted"
      true
    when "contacts"
      return false unless @user
      return true if owner? || can_administer?
      Contact.confirmed_between?(@user, @resource.user)
    when "restricted"
      return false unless @user
      owner? || can_administer?
    else
      false
    end
  end

  def can_create?
    return false unless @user
    return true if system_admin?

    override = app_permission
    return override.can_create if override

    @user.content_creator? || @user.admin?
  end

  def can_update?
    return false unless @user
    return true if system_admin?
    override = app_permission
    return override.can_update if override
    @resource.respond_to?(:user_id) ? write_access_by_role? : admin_access?
  end

  def can_delete?
    return false unless @user
    return true if system_admin?
    override = app_permission
    return override.can_delete if override
    @resource.respond_to?(:user_id) ? write_access_by_role? : admin_access?
  end

  private

  def write_access_by_role?
    return false unless record?
    @user.admin? || (@user.content_creator? && owner?)
  end

  def admin_access?
    @user.admin? || @user.system_admin?
  end

  def system_admin?
    @user&.system_admin?
  end

  def can_administer?
    @user&.can_administer?
  end

  def owner?
    record? && @resource.user_id == @user.id
  end

  def record?
    @resource.is_a?(ApplicationRecord)
  end

  def app_permission
    return nil unless @user
    AppPermission.find_by(user: @user, app_name: app_name_for(@resource))
  end

  def app_name_for(resource)
    case resource
    when Event, EventType, :event_tracker then "event_tracker"
    when :blog_posts                      then "blog_posts"
    when :recipes                         then "recipes"
    when :photo_albums                    then "photo_albums"
    end
  end
end
