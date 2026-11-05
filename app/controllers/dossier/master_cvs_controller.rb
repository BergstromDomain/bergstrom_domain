# app/controllers/dossier/master_cvs_controller.rb

# Download Master CV: the signed-in user's whole Dossier as one CV. Needs a
# Profile, which the CV's header and summary come from.
class Dossier::MasterCvsController < ApplicationController
  include Navigable
  include Dossier::CvDownloadable

  before_action :require_dossier_access
  before_action :set_cv
  before_action :require_profile, except: :show

  # Download Word / Download PDF, or a link to create the Profile first.
  def show
  end

  def pdf  = send_cv_pdf(@cv)
  def docx = send_cv_docx(@cv)

  private

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  def set_cv
    @cv = Dossier::CvDocument.new(current_user)
  end

  def require_profile
    redirect_to edit_dossier_profile_path, alert: NO_PROFILE unless @cv.profile?
  end
end
