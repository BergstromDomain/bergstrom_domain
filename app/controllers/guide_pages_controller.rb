# app/controllers/guide_pages_controller.rb
class GuidePagesController < ApplicationController
  include Navigable
  allow_unauthenticated_access only: %i[index show]
  before_action :resume_session_if_present
  before_action :set_guide_page, only: %i[show edit update destroy]
  before_action :set_policy,     only: %i[show edit update destroy]
  before_action :require_admin,  only: %i[new create]

  def index
    @query = params[:q].to_s.strip
    # Sorted by App Section label, then Title — app_section_label isn't a
    # DB column (it's a Ruby-side lookup off the enum), so this sorts in
    # Ruby rather than SQL, same "fine at this app's scale" reasoning as
    # BlogPostFilter's own sort.
    @guide_pages = GuidePage.search(@query).to_a
      .sort_by { |guide_page| [ guide_page.app_section_label, guide_page.title.downcase ] }
  end

  def show
  end

  def new
    @guide_page = GuidePage.new
  end

  def create
    @guide_page = GuidePage.new(guide_page_params)
    if @guide_page.save
      toast_created(@guide_page)
      redirect_to @guide_page
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to guide_pages_path, alert: "Not authorised." unless @policy.can_update?
  end

  def update
    unless @policy.can_update?
      redirect_to guide_pages_path, alert: "Not authorised." and return
    end
    previous_label = @guide_page.to_toast_label
    if @guide_page.update(guide_page_params)
      toast_updated(@guide_page, previous_label: previous_label)
      redirect_to @guide_page
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @policy.can_delete?
      redirect_to guide_pages_path, alert: "Not authorised." and return
    end
    @guide_page.destroy
    toast_deleted(@guide_page)
    redirect_to guide_pages_path
  end

  private

  def require_admin
    unless current_user&.can_administer?
      redirect_to guide_pages_path, alert: "Not authorised."
    end
  end

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end

  def set_policy
    @policy = Policy.new(current_user, @guide_page)
  end

  def set_guide_page
    @guide_page = GuidePage.friendly.find(params[:id])
  end

  def guide_page_params
    params.require(:guide_page).permit(:title, :app_section, :body,
      :supports_guest, :supports_user, :supports_content_creator)
  end
end
