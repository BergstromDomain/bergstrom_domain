# spec/requests/dossier/master_cvs_spec.rb
require "rails_helper"

RSpec.describe "Dossier Master CV downloads", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:charlie) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Downloads the master CV as a PDF named after the display name and date" do
      create(:dossier_profile, user: charlie, display_name: "Alex Example")
      sign_in_as(charlie)

      travel_to(Date.new(2026, 11, 5)) { get pdf_dossier_master_cv_path }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("attachment", "Alex_Example_CV_2026-11-05.pdf")
      expect(response.body.byteslice(0, 5)).to eq("%PDF-")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Sends a visitor to sign in" do
      get pdf_dossier_master_cv_path

      expect(response).to redirect_to(new_session_path)
    end

    it "Turns away an App User" do
      sign_in_as(create(:user))

      get pdf_dossier_master_cv_path

      expect(response).to redirect_to(dossier_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Asks for a Profile first when there isn't one" do
      sign_in_as(charlie)

      get pdf_dossier_master_cv_path

      expect(response).to redirect_to(edit_dossier_profile_path)
      expect(flash[:alert]).to eq("Create your Profile first — the CV starts from it.")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Uses only the signed-in user's own data" do
      create(:dossier_profile, user: charlie, display_name: "Charlie")
      create(:dossier_profile, display_name: "Someone Else")
      sign_in_as(charlie)

      get pdf_dossier_master_cv_path

      expect(response.headers["Content-Disposition"]).to include("Charlie_CV_")
    end
  end
end
