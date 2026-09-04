# app/controllers/likes_controller.rb
class LikesController < ApplicationController
  before_action :set_blog_post

  def create
    unless Policy.new(current_user, @blog_post).can_read?
      redirect_to chronicle_path, alert: "Not authorised."
      return
    end

    unless Like::FACES.key?(params[:face])
      redirect_to @blog_post, alert: "Invalid reaction."
      return
    end

    @blog_post.likes.find_or_initialize_by(user: current_user).update!(face: params[:face])
    redirect_to @blog_post
  end

  private

  def set_blog_post
    @blog_post = BlogPost.friendly.find(params[:blog_post_id])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end
end
