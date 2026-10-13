# app/controllers/likes_controller.rb
class LikesController < ApplicationController
  before_action :set_likeable

  def create
    unless Policy.new(current_user, @likeable).can_read?
      redirect_to likeable_home_path, alert: "Not authorised."
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
      redirect_to likeable_home_path, alert: "Not authorised."
      return
    end

    @likeable.likes.find_by(user: current_user)&.clear!
    redirect_to @likeable
  end

  private

  # Nested under whichever likeable route matched: blog_posts/:blog_post_id/like
  # or recipes/:recipe_id/like.
  LIKEABLES = { blog_post_id: BlogPost, recipe_id: Recipe }.freeze

  def set_likeable
    key, model = LIKEABLES.find { |param, _| params.key?(param) }
    @likeable = model.friendly.find(params[key])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end

  def likeable_home_path
    @likeable.is_a?(Recipe) ? cookbook_path : chronicle_path
  end
end
