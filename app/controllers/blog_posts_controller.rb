# app/controllers/blog_posts_controller.rb
class BlogPostsController < ApplicationController
  include Navigable

  before_action :require_create_access, only: %i[new create convert_format]

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

  def convert_format
    case params[:source]
    when "markdown"
      render json: { html: markdown_to_html(params[:content].to_s) }
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

  def blog_post_params
    params.require(:blog_post).permit(:title, :body, :format, :blog_category_id, :sub_category, :topic)
  end

  def add_co_authors
    confirmed_ids = Contact.confirmed_contact_ids_for(current_user)
    (submitted_author_ids & confirmed_ids).each do |id|
      @blog_post.blog_post_authors.find_or_create_by!(user_id: id)
    end
  end

  def submitted_author_ids
    Array(params.dig(:blog_post, :author_ids)).map(&:to_i)
  end

  def set_author_lists(selected_ids)
    contacts = User.where(id: Contact.confirmed_contact_ids_for(current_user)).order(:last_name, :first_name)
    @selected_authors  = contacts.select { |user| selected_ids.include?(user.id) }
    @available_authors = contacts - @selected_authors
  end

  def markdown_to_html(markdown)
    # header_ids: nil turns off Commonmarker's default heading-anchor-link
    # generation (it's on by default, even with header_ids left unset) —
    # Quill has no use for those anchors and they'd just clutter the editor.
    Commonmarker.to_html(markdown, options: { render: { unsafe: true }, extension: { header_ids: nil } })
  end
end
