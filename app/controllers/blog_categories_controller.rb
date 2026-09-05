# app/controllers/blog_categories_controller.rb
class BlogCategoriesController < ApplicationController
  include Navigable
  allow_unauthenticated_access only: %i[index show]
  before_action :resume_session_if_present
  before_action :set_blog_category, only: %i[show edit update destroy]
  before_action :set_policy,         only: %i[show edit update destroy]
  before_action :require_admin,      only: %i[new create]

  def index
    @blog_categories = BlogCategory.order("LOWER(name) ASC")
  end

  def show
  end

  def new
    @blog_category = BlogCategory.new
  end

  def create
    @blog_category = BlogCategory.new(blog_category_params)
    if @blog_category.save
      toast_created(@blog_category)
      redirect_to @blog_category
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to blog_categories_path, alert: "Not authorised." unless @policy.can_update?
  end

  def update
    unless @policy.can_update?
      redirect_to blog_categories_path, alert: "Not authorised." and return
    end
    previous_label = @blog_category.to_toast_label
    if @blog_category.update(blog_category_params)
      toast_updated(@blog_category, previous_label: previous_label)
      redirect_to @blog_category
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @policy.can_delete?
      redirect_to blog_categories_path, alert: "Not authorised." and return
    end
    @blog_category.destroy
    if @blog_category.errors.any?
      toast_error(@blog_category)
      redirect_to blog_category_path(@blog_category)
    else
      toast_deleted(@blog_category)
      redirect_to blog_categories_path
    end
  end

  private

  def require_admin
    unless current_user&.can_administer?
      redirect_to blog_categories_path, alert: "Not authorised."
    end
  end

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end

  def set_policy
    @policy = Policy.new(current_user, @blog_category)
  end

  def set_blog_category
    @blog_category = BlogCategory.friendly.find(params[:id])
  end

  def blog_category_params
    params.require(:blog_category).permit(:name, :description, :icon)
  end
end
