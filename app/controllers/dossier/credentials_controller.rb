# app/controllers/dossier/credentials_controller.rb

# The signed-in user's Credentials (degrees, certifications, courses…), at
# /dossier/credentials, grouped by Credential Type; training types list only
# Completed ones (Browse and Filter Courses list the rest). Every table sorts
# by ?sort=&direction=. New takes an optional
# engagement_id or assignment_id to preselect where it sits (from those pages'
# "Add Training" buttons), and creating returns there.
class Dossier::CredentialsController < ApplicationController
  include Navigable
  before_action :require_dossier_access, only: %i[index new create]
  before_action :set_credential, only: %i[show edit update destroy]

  helper_method :engagement_choices, :assignment_choices

  def index
    mine = current_user.dossier_credentials.kept
    listed = Dossier::Credential.where(status: "completed")
                                .or(Dossier::Credential.where(credential_type_id: Dossier::CredentialType.where(training: false).select(:id)))
    credentials = mine.merge(listed).newest_first
                      .includes(:provider, { engagement: :employer }, assignment: :client, credential_skills: :skill)
                      .group_by(&:credential_type_id)
    @sort = Dossier::CredentialSort.new(params[:sort], params[:direction],
                                        taken_during: ->(credential) { helpers.credential_taken_during_label(credential) })
    # Every type the user has, even one with nothing Completed (its frame says so).
    @groups = Dossier::CredentialType.where(id: mine.select(:credential_type_id)).in_order
                                     .map { |type| [ type, @sort.apply(credentials.fetch(type.id, [])) ] }
  end

  def show
    redirect_to dossier_credentials_path, alert: "Not authorised." unless Policy.new(current_user, @credential).can_read?
  end

  def new
    @credential = current_user.dossier_credentials.build(
      credential_type: Dossier::CredentialType.where(training: true).in_order.first,
      engagement: engagement_choices.find_by(id: params[:engagement_id]),
      assignment: assignment_choices.find_by(id: params[:assignment_id])
    )
  end

  def create
    @credential = current_user.dossier_credentials.build(credential_params)
    assign_links
    if @credential.save
      toast_created(@credential)
      redirect_to return_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to dossier_credentials_path, alert: "Not authorised." unless Policy.new(current_user, @credential).can_update?
  end

  def update
    unless Policy.new(current_user, @credential).can_update?
      redirect_to dossier_credentials_path, alert: "Not authorised." and return
    end
    previous_label = @credential.to_toast_label
    @credential.assign_attributes(credential_params)
    assign_links
    if @credential.save
      toast_updated(@credential, previous_label: previous_label)
      redirect_to @credential
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless Policy.new(current_user, @credential).can_delete?
      redirect_to dossier_credentials_path, alert: "Not authorised." and return
    end
    @credential.destroy
    toast_deleted(@credential)
    redirect_to return_path
  end

  private

  def engagement_choices
    current_user.dossier_engagements.kept.includes(:employer).newest_first
  end

  def assignment_choices
    Dossier::Assignment.kept.joins(:engagement).merge(current_user.dossier_engagements.kept)
                       .includes(:client, engagement: :employer).order("dossier_engagements.start_on DESC", start_on: :desc)
  end

  # Only the user's own Engagements and Assignments; an Assignment sets its
  # Engagement.
  def assign_links
    links = params.require(:dossier_credential)
    @credential.assignment = assignment_choices.find_by(id: links[:assignment_id])
    @credential.engagement = engagement_choices.find_by(id: links[:engagement_id])
  end

  def return_path
    if @credential.assignment then dossier_assignment_path(@credential.assignment, anchor: "training")
    elsif @credential.engagement then dossier_engagement_path(@credential.engagement, anchor: "training")
    else dossier_credentials_path
    end
  end

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  def set_credential
    @credential = Dossier::Credential.includes(credential_skills: :skill, files_attachments: :blob).find(params[:id])
  end

  def credential_params
    params.require(:dossier_credential).permit(:credential_type_id, :title, :provider_id,
                                               :start_year, :start_month_number, :start_day,
                                               :end_year, :end_month_number, :end_day,
                                               :expires_year, :expires_month_number, :expires_day,
                                               :certificate_number, :verification_url,
                                               :hours, :skills_text, :description, :status, files: [])
  end
end
