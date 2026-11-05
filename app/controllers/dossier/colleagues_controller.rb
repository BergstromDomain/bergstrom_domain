# app/controllers/dossier/colleagues_controller.rb

# An Assignment's Colleagues, added and edited from its page. Only those who
# can see them (the owner and Admins) and may update the Assignment get in.
class Dossier::ColleaguesController < ApplicationController
  include Navigable
  before_action :set_assignment
  before_action :require_access
  before_action :set_colleague, only: %i[edit update destroy]

  def new
    @colleague = @assignment.colleagues.build
  end

  def create
    @colleague = @assignment.colleagues.build(colleague_params)
    if @colleague.save
      toast_created(@colleague)
      redirect_to colleagues_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    previous_label = @colleague.to_toast_label
    if @colleague.update(colleague_params)
      toast_updated(@colleague, previous_label: previous_label)
      redirect_to colleagues_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @colleague.destroy
    toast_deleted(@colleague)
    redirect_to colleagues_path
  end

  private

  def set_assignment
    @assignment = Dossier::Assignment.find(params[:assignment_id])
  end

  def require_access
    return if @assignment.private_details_visible_to?(current_user) && Policy.new(current_user, @assignment).can_update?

    redirect_to dossier_engagements_path, alert: "Not authorised."
  end

  # Only this Assignment's: another's id is a 404.
  def set_colleague
    @colleague = @assignment.colleagues.find(params[:id])
  end

  def colleagues_path = dossier_assignment_path(@assignment, anchor: "colleagues")

  def colleague_params
    params.require(:dossier_colleague).permit(:name, :position, :mobile, :email, :linkedin_url, :comment)
  end
end
