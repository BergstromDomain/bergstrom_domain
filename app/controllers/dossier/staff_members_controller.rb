# app/controllers/dossier/staff_members_controller.rb

# A Vendor's or Customer's Staff on an Assignment, added and edited from its
# page. Only those who can see them (the owner and Admins) and may update the
# Assignment get in.
class Dossier::StaffMembersController < ApplicationController
  include Navigable
  before_action :set_partner
  before_action :require_access
  before_action :set_staff_member, only: %i[edit update destroy]

  def new
    @staff_member = @partner.staff_members.build
  end

  def create
    @staff_member = @partner.staff_members.build(staff_member_params)
    if @staff_member.save
      toast_created(@staff_member)
      redirect_to partners_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    previous_label = @staff_member.to_toast_label
    if @staff_member.update(staff_member_params)
      toast_updated(@staff_member, previous_label: previous_label)
      redirect_to partners_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @staff_member.destroy
    toast_deleted(@staff_member)
    redirect_to partners_path
  end

  private

  # Only this Assignment's Vendor or Customer: another's id is a 404.
  def set_partner
    @assignment = Dossier::Assignment.find(params[:assignment_id])
    @partner = @assignment.partners.includes(:organisation).find(params[:partner_id])
  end

  def require_access
    return if @assignment.private_details_visible_to?(current_user) && Policy.new(current_user, @assignment).can_update?

    redirect_to dossier_engagements_path, alert: "Not authorised."
  end

  # Only this Vendor's or Customer's: another's id is a 404.
  def set_staff_member
    @staff_member = @partner.staff_members.find(params[:id])
  end

  def partners_path = dossier_assignment_path(@assignment, anchor: @partner.kind.pluralize)

  def staff_member_params
    params.require(:dossier_staff_member).permit(*Dossier::ContactDetails::FIELDS)
  end
end
