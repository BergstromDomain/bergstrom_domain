# app/controllers/blog_posts_controller.rb
class BlogPostsController < ApplicationController
  include Navigable

  allow_unauthenticated_access only: %i[index show filter]
  before_action :resume_session_if_present, only: %i[index show filter]
  before_action :set_blog_post,             only: %i[show edit update publish unpublish destroy restore]
  before_action :require_create_access,     only: %i[new create convert_format]
  before_action :require_write_access,      only: %i[edit update publish unpublish]
  before_action :require_delete_access,     only: %i[destroy]
  before_action :require_admin,             only: %i[deleted restore]

  def index
    scope = visible_blog_posts_scope

    @total_count = scope.count
    @category_param = params[:category_id].presence
    @subject_param  = params[:subject].presence
    @topic_param    = params[:topic].presence

    if @category_param
      @category = find_category_from_param(@category_param)
      redirect_to(blog_posts_path) && return if @category.nil? && @category_param != "none"
      @category_scope = @category ? scope.where(blog_category: @category) : scope.where(blog_category_id: nil)
      @category_label = @category&.name || "(Uncategorized)"
      @category_count = @category_scope.count
    end

    if @subject_param
      @subject = @subject_param == "none" ? nil : @subject_param
      @subject_scope = @subject.present? ? @category_scope.where(subject: @subject) : @category_scope.where(subject: [ nil, "" ])
      @subject_label = @subject.presence || "(No Subject)"
      @subject_count = @subject_scope.count
    end

    if @topic_param
      @topic = @topic_param == "none" ? nil : @topic_param
      post_scope = @topic.present? ? @subject_scope.where(topic: @topic) : @subject_scope.where(topic: [ nil, "" ])
      @topic_label = @topic.presence || "(No Topic)"
      @posts = post_scope.includes(:user, :authors, :blog_category).order(created_at: :desc)
    elsif @subject_param
      @topics = grouped_counts(@subject_scope, :topic)
    elsif @category_param
      @subjects = grouped_counts(@category_scope, :subject)
    else
      @categories = category_counts(scope)
    end
  end

  FILTER_SORT_COLUMNS = %w[category subject topic title author created comments smiles].freeze

  def filter
    posts = visible_blog_posts_scope.includes(:user, :blog_category).to_a

    @mode  = params[:mode] == "sql" ? "sql" : "basic"
    @query = params[:query].to_s
    @filter_error = nil
    @posts = posts

    begin
      ast =
        if @mode == "sql"
          @query.presence && Jql::Parser.parse(@query)
        else
          BlogPostFilter.basic_ast(**basic_filter_params)
        end

      if ast
        BlogPostFilter::EVALUATOR.validate!(ast)
        @posts = posts.select { |post| BlogPostFilter::EVALUATOR.matches?(ast, BlogPostFilter.attributes_for(post)) }
      end
    rescue Jql::ParseError => e
      @filter_error = e.message
      @posts = []
    end

    @sort      = FILTER_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "created"
    @direction = params[:direction] == "asc" ? "asc" : "desc"
    @posts = BlogPostFilter.sort(@posts, @sort, @direction)

    set_filter_options(posts)
  end

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

  def destroy
    @blog_post.update!(deleted_at: Time.current)
    redirect_to chronicle_path, notice: "Blog post deleted. An admin can restore it within 30 days."
  end

  def deleted
    @blog_posts = BlogPost.discarded.order(deleted_at: :desc)
  end

  def restore
    @blog_post.update!(deleted_at: nil)
    redirect_to deleted_blog_posts_path, notice: "Blog post restored."
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

  # Mirrors PeopleController#index's exact three-way visibility split
  # (app/controllers/people_controller.rb) — BlogPost already has all three
  # scopes from Foundation.
  def visible_blog_posts_scope
    if !authenticated?
      BlogPost.visible_to_visitors
    elsif current_user.can_administer?
      BlogPost.visible_to_admins
    else
      BlogPost.visible_to_users(current_user)
    end
  end

  def find_category_from_param(param)
    return nil if param == "none"
    BlogCategory.friendly.find(param)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Ruby-side grouping (not SQL GROUP BY) — deliberately simple at this app's
  # scale, and sidesteps NULL-vs-empty-string edge cases entirely.
  def grouped_counts(scope, column)
    scope.pluck(column).map { |v| v.presence || "none" }.tally.sort.to_h
  end

  def category_counts(scope)
    counts = BlogCategory.order("LOWER(name) ASC").filter_map do |category|
      count = scope.where(blog_category: category).count
      [ category, count ] if count.positive?
    end.to_h
    uncategorized = scope.where(blog_category_id: nil).count
    counts[:uncategorized] = uncategorized if uncategorized.positive?
    counts
  end

  def basic_filter_params
    category = params[:category_id].presence && safe_find_category(params[:category_id])
    author   = params[:author_id].presence && safe_find_author(params[:author_id])

    {
      category:      category&.name,
      subject:       params[:subject].presence,
      topic:         params[:topic].presence,
      author_name:   author && "#{author.first_name} #{author.last_name}",
      created_range: created_range_for(params[:created]),
      published:     published_filter_for(params[:published])
    }
  end

  def published_filter_for(value)
    case value
    when "published" then "true"
    when "draft"      then "false"
    end
  end

  def safe_find_category(id)
    BlogCategory.friendly.find(id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def safe_find_author(id)
    User.find(id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def created_range_for(value)
    case value
    when "today"      then Date.current..Date.current
    when "this_week"  then Date.current.beginning_of_week..Date.current
    when "this_month" then Date.current.beginning_of_month..Date.current
    when "this_year"  then Date.current.beginning_of_year..Date.current
    end
  end

  def set_filter_options(posts)
    @category_options = BlogCategory.where(id: posts.filter_map(&:blog_category_id)).order("LOWER(name) ASC")
    @subject_options   = posts.map(&:subject).compact_blank.uniq.sort
    @topic_options     = posts.map(&:topic).compact_blank.uniq.sort
    @author_options    = posts.map(&:user).uniq.sort_by { |user| [ user.last_name.downcase, user.first_name.downcase ] }
  end

  def require_create_access
    unless Policy.new(current_user, :blog_posts).can_create?
      redirect_to chronicle_path, alert: "Not authorised."
    end
  end

  def require_write_access
    @policy = Policy.new(current_user, @blog_post)
    redirect_to @blog_post, alert: "Not authorised." unless @policy.can_update?
  end

  def require_delete_access
    @policy = Policy.new(current_user, @blog_post)
    redirect_to @blog_post, alert: "Not authorised." unless @policy.can_delete?
  end

  def require_admin
    redirect_to chronicle_path, alert: "Not authorised." unless current_user&.can_administer?
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
    params.require(:blog_post).permit(:title, :body, :format, :blog_category_id, :subject, :topic, :blog_image)
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
