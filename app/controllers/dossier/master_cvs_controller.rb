# app/controllers/dossier/master_cvs_controller.rb

# Download Master CV: the signed-in user's whole Dossier as one CV, generated
# and downloaded on demand (no stored copies, Q-D8; no toast, Q-D14). Needs a
# Profile, which the CV's header and summary come from.
class Dossier::MasterCvsController < ApplicationController
  include Navigable
  include PdfDownloadable

  DOCX_TYPE = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

  before_action :require_dossier_access
  before_action :set_cv

  def pdf
    send_data render_pdf(template: "dossier/master_cvs/cv", assigns: { cv: @cv }, footer: @cv.header.name),
              filename: @cv.filename("pdf"), type: "application/pdf", disposition: "attachment"
  end

  def docx
    send_data Dossier::CvDocx.new(@cv).render, filename: @cv.filename("docx"), type: DOCX_TYPE, disposition: "attachment"
  end

  private

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  def set_cv
    @cv = Dossier::CvDocument.new(current_user)
    redirect_to edit_dossier_profile_path, alert: "Create your Profile first — the CV starts from it." unless @cv.profile?
  end
end
