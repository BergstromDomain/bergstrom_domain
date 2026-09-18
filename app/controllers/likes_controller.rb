# app/controllers/likes_controller.rb
class LikesController < ApplicationController
  before_action :set_likeable

  def create
    unless Policy.new(current_user, @likeable).can_read?
      redirect_to chronicle_path, alert: "Not authorised."
      return
    end

    unless Like::FACES.key?(params[:face])
      redirect_to @likeable, alert: "Invalid reaction."
      return
    end

    @likeable.likes.find_or_initialize_by(user: current_user).update!(face: params[:face])
    redirect_to @likeable
  end

  # Clears the current user's reaction (Like row stays, face becomes nil) —
  # a DELETE on the Like "resource" reads naturally even though nothing is
  # actually destroyed.
  def destroy
    unless Policy.new(current_user, @likeable).can_read?
      redirect_to chronicle_path, alert: "Not authorised."
      return
    end

    @likeable.likes.find_by(user: current_user)&.clear!
    redirect_to @likeable
  end

  private

  # Only Chronicle is wired up so far — this stays blog-post-specific until
  # another app (e.g. Cookbook's Recipe) adds its own nested :like route.
  def set_likeable
    @likeable = BlogPost.friendly.find(params[:blog_post_id])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end
end
