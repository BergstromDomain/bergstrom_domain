# spec/requests/dossier/cv_variant_downloads_spec.rb
require "rails_helper"

RSpec.describe "Dossier CV Variant downloads", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:charlie) { create(:user, :content_creator) }
  let(:variant) { create(:dossier_cv_variant, user: charlie, name: "QE Lead — Acme", summary_override: "For Acme.") }

  before { create(:dossier_profile, user: charlie, display_name: "Alex Example") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Downloads the variant as a Word file with its own summary and filename" do
      sign_in_as(charlie)

      travel_to(Date.new(2026, 11, 6)) { get docx_dossier_cv_variant_path(variant) }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Dossier::CvDownloadable::DOCX_TYPE)
      expect(response.headers["Content-Disposition"]).to include("attachment", "Alex_Example_CV_QE_Lead_Acme_2026-11-06.docx")
      expect(docx_paragraphs(response.body)).to include([ nil, "For Acme." ])
    end

    it "Downloads the variant as a PDF" do
      sign_in_as(charlie)

      get pdf_dossier_cv_variant_path(variant)

      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("Alex_Example_CV_QE_Lead_Acme_")
      expect(response.body.byteslice(0, 5)).to eq("%PDF-")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Turns away another Content Creator" do
      sign_in_as(create(:user, :content_creator))

      [ pdf_dossier_cv_variant_path(variant), docx_dossier_cv_variant_path(variant) ].each do |path|
        get path

        expect(response).to redirect_to(dossier_cv_variants_path)
      end
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lets an Admin download someone's variant, built from the owner's data" do
      sign_in_as(create(:user, :admin))

      get docx_dossier_cv_variant_path(variant)

      expect(docx_paragraphs(response.body).first).to eq([ "Title", "Alex Example" ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Asks for a Profile first when the owner has none" do
      charlie.dossier_profile.destroy!
      sign_in_as(charlie)

      get pdf_dossier_cv_variant_path(variant)

      expect(response).to redirect_to(edit_dossier_profile_path)
      expect(flash[:alert]).to eq(Dossier::CvDownloadable::NO_PROFILE)
    end
  end
end
