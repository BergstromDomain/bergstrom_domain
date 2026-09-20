# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  before_action :set_commentable,                only: %i[create]
  before_action :set_comment,                    only: %i[update destroy]
  before_action :require_comment_owner_or_admin!, only: %i[update destroy]

  def create
    unless Policy.new(current_user, @commentable).can_read?
      redirect_to chronicle_path, alert: "Not authorised."
      return
    end

    comment = @commentable.comments.new(comment_params.merge(user: current_user))
    comment.parent = resolve_parent(params[:comment][:parent_id])

    if comment.save
      redirect_to @commentable
    else
      redirect_to @commentable, alert: comment.errors.full_messages.to_sentence
    end
  end

  def update
    if @comment.update(comment_params)
      redirect_to @comment.commentable
    else
      redirect_to @comment.commentable, alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    commentable = @comment.commentable
    @comment.destroy
    redirect_to commentable, notice: "Comment deleted."
  end

  private

  # Only Chronicle is wired up so far — this stays blog-post-specific until
  # another app (e.g. Cookbook's Recipe) adds its own nested :comment route.
  def set_commentable
    @commentable = BlogPost.friendly.find(params[:blog_post_id])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def require_comment_owner_or_admin!
    return if @comment.user_id == current_user.id || current_user.can_administer?
    redirect_to @comment.commentable, alert: "Not authorised."
  end

  # A reply to a reply flattens onto the same thread rather than nesting
  # further — comments are only ever 2 levels deep (see Comment's own
  # parent_must_be_top_level validation for the defense-in-depth backstop).
  def resolve_parent(parent_id)
    return nil if parent_id.blank?
    target = Comment.find(parent_id)
    target.parent_id ? target.parent : target
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
