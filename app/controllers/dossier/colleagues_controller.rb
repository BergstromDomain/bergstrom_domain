# app/controllers/dossier/colleagues_controller.rb

# An Assignment's Colleagues, added and edited from its page. Only those who
# can see them (the owner and Admins) and may update the Assignment get in.
class Dossier::ColleaguesController < ApplicationController
  include Navigable
  include Dossier::LinksPeople
  before_action :set_assignment
  before_action :require_access
  before_action :set_colleague, only: %i[edit update destroy]

  def new
    @colleague = @assignment.colleagues.build
    pick_person(@colleague, params[:person_id])
    find_people
  end

  def create
    @colleague = @assignment.colleagues.build
    pick_person(@colleague, params.dig(:dossier_colleague, :person_id))
    assign_contact(@colleague, colleague_params)
    if @colleague.save
      toast_created(@colleague)
      redirect_to colleagues_path
    else
      find_people
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    previous_label = @colleague.to_toast_label
    assign_contact(@colleague, colleague_params)
    if @colleague.save
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
    return if @assignment.private_details_visible_to?(current_user) && Policy.new(current_user, @assignment).can_update? &&
              !@assignment.hidden?

    redirect_to dossier_engagements_path, alert: "Not authorised."
  end

  # Only this Assignment's: another's id is a 404.
  def set_colleague
    @colleague = @assignment.colleagues.includes(Dossier::ContactDetails::PRELOAD).find(params[:id])
  end

  def colleagues_path = dossier_assignment_path(@assignment, anchor: "colleagues")

  def colleague_params
    contact_params(:dossier_colleague)
  end
end
