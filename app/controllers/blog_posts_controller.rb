# app/controllers/blog_posts_controller.rb
class BlogPostsController < ApplicationController
  include Navigable

  allow_unauthenticated_access only: %i[show]
  before_action :resume_session_if_present, only: %i[show]
  before_action :set_blog_post,             only: %i[show edit update publish unpublish]
  before_action :require_create_access,     only: %i[new create convert_format]
  before_action :require_write_access,      only: %i[edit update publish unpublish]

  def new
    @blog_post = current_user.blog_posts.build
    set_author_lists([])
  end

  def create
    @blog_post = current_user.blog_posts.build(blog_post_params)
    if @blog_post.save
      add_co_authors
      redirect_to chronicle_path, notice: "Blog post saved as a draft."
    else
      set_author_lists(submitted_author_ids)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @policy = Policy.new(current_user, @blog_post)
    unless @policy.can_read?
      redirect_to chronicle_path, alert: "You do not have permission to view that blog post."
    end
  end

  def edit
    set_author_lists(@blog_post.blog_post_authors.where.not(user_id: @blog_post.user_id).pluck(:user_id))
  end

  def update
    if @blog_post.update(blog_post_params.merge(published_at: nil))
      sync_co_authors
      redirect_to @blog_post, notice: "Blog post updated."
    else
      set_author_lists(submitted_author_ids)
      render :edit, status: :unprocessable_entity
    end
  end

  def publish
    @blog_post.published_at = Time.current
    if @blog_post.save
      redirect_to @blog_post, notice: "Blog post published."
    else
      redirect_to @blog_post, alert: "Cannot publish: #{@blog_post.errors.full_messages.to_sentence}"
    end
  end

  def unpublish
    @blog_post.update!(published_at: nil)
    redirect_to @blog_post, notice: "Blog post moved back to draft."
  end

  def convert_format
    case params[:source]
    when "markdown"
      render json: { html: BlogPost.render_markdown(params[:content]) }
    when "html"
      render json: { markdown: ReverseMarkdown.convert(params[:content].to_s) }
    else
      head :bad_request
    end
  end

  private

  def require_create_access
    unless Policy.new(current_user, :blog_posts).can_create?
      redirect_to chronicle_path, alert: "Not authorised."
    end
  end

  def require_write_access
    @policy = Policy.new(current_user, @blog_post)
    redirect_to @blog_post, alert: "Not authorised." unless @policy.can_update?
  end

  def set_blog_post
    @blog_post = BlogPost.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end

  def blog_post_params
    params.require(:blog_post).permit(:title, :body, :format, :blog_category_id, :sub_category, :topic, :blog_image)
  end

  def add_co_authors
    confirmed_ids = Contact.confirmed_contact_ids_for(@blog_post.user)
    (submitted_author_ids & confirmed_ids).each do |id|
      @blog_post.blog_post_authors.find_or_create_by!(user_id: id)
    end
  end

  # Unlike add_co_authors (only ever adds, correct for a brand-new post with
  # no existing co-authors to remove), Edit must reconcile the submitted list
  # both ways — the primary author's own row (user_id) is never touched here,
  # since it's excluded from the shuttle entirely, not something the client
  # ever submits a choice about.
  def sync_co_authors
    confirmed_ids  = Contact.confirmed_contact_ids_for(@blog_post.user)
    submitted_ids  = submitted_author_ids & confirmed_ids
    current_co_ids = @blog_post.blog_post_authors.where.not(user_id: @blog_post.user_id).pluck(:user_id)

    (current_co_ids - submitted_ids).each { |id| @blog_post.blog_post_authors.find_by(user_id: id)&.destroy }
    (submitted_ids - current_co_ids).each { |id| @blog_post.blog_post_authors.find_or_create_by!(user_id: id) }
  end

  def submitted_author_ids
    Array(params.dig(:blog_post, :author_ids)).map(&:to_i)
  end

  def set_author_lists(selected_ids)
    contacts = User.where(id: Contact.confirmed_contact_ids_for(@blog_post.user)).order(:last_name, :first_name)
    @selected_authors  = contacts.select { |user| selected_ids.include?(user.id) }
    @available_authors = contacts - @selected_authors
  end
end
