# app/controllers/dossier/assignment_partners_controller.rb

# An Assignment's Vendors and Customers, added and edited from its page
# (new takes kind=vendor|customer). Only those who can see them (the owner
# and Admins) and may update the Assignment get in.
class Dossier::AssignmentPartnersController < ApplicationController
  include Navigable
  before_action :set_assignment
  before_action :require_access
  before_action :set_partner, only: %i[edit update destroy]

  def new
    kind = Dossier::AssignmentPartner::KINDS.key?(params[:kind]) ? params[:kind] : "vendor"
    @partner = @assignment.partners.build(kind: kind)
  end

  def create
    @partner = @assignment.partners.build(partner_params)
    if @partner.save
      toast_created(@partner)
      redirect_to partners_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    previous_label = @partner.to_toast_label
    if @partner.update(partner_params.except(:kind))
      toast_updated(@partner, previous_label: previous_label)
      redirect_to partners_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @partner.destroy
    toast_deleted(@partner)
    redirect_to partners_path
  end

  private

  def set_assignment
    @assignment = Dossier::Assignment.find(params[:assignment_id])
  end

  def require_access
    return if @assignment.private_details_visible_to?(current_user) && Policy.new(current_user, @assignment).can_update?

    redirect_to dossier_engagements_path, alert: "Not authorised."
  end

  def set_partner
    @partner = @assignment.partners.find(params[:id])
  end

  def partners_path = dossier_assignment_path(@assignment, anchor: "partners")

  def partner_params
    permitted = params.require(:dossier_assignment_partner).permit(:kind, :organisation_id, :scope)
    permitted[:kind] = "vendor" unless Dossier::AssignmentPartner::KINDS.key?(permitted[:kind])
    permitted
  end
end
