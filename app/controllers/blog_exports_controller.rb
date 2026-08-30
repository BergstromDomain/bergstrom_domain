# app/controllers/blog_exports_controller.rb
class BlogExportsController < ApplicationController
  include Navigable

  before_action :require_can_export

  def index
  end

  def print
    @posts = visible_posts
  end

  def csv
    csv_data = BlogPostExportService.new(visible_posts).generate_csv
    filename = "blog_posts_export_#{Date.current.iso8601}.csv"

    send_data csv_data,
              type:        "text/csv; charset=utf-8",
              filename:    filename,
              disposition: "attachment"
  end

  private

  def require_can_export
    redirect_to chronicle_path, alert: "Not authorised." unless current_user&.can_export?
  end

  def visible_posts
    scope = current_user.can_administer? ? BlogPost.visible_to_admins : BlogPost.visible_to_users(current_user)
    scope.includes(:user, :blog_category).order(created_at: :desc)
  end
end
