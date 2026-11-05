# app/controllers/concerns/dossier/cv_downloadable.rb

# Sends a Dossier::CvDocument as a PDF or Word file, generated on demand
# (no stored copies, Q-D8; no toast, Q-D14). Shared by Download Master CV
# and the CV Variant downloads.
module Dossier
  module CvDownloadable
    extend ActiveSupport::Concern
    include PdfDownloadable

    DOCX_TYPE = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    NO_PROFILE = "Create your Profile first — the CV starts from it."

    private

    def send_cv_pdf(cv)
      send_data render_pdf(template: "dossier/master_cvs/cv", assigns: { cv: cv }, footer: cv.header.name),
                filename: cv.filename("pdf"), type: "application/pdf", disposition: "attachment"
    end

    def send_cv_docx(cv)
      send_data Dossier::CvDocx.new(cv).render, filename: cv.filename("docx"), type: DOCX_TYPE, disposition: "attachment"
    end
  end
end
