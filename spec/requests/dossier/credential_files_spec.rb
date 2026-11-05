# spec/requests/dossier/credential_files_spec.rb
require "rails_helper"

RSpec.describe "Dossier Credential files", type: :request do
  let(:charlie) { create(:user, :content_creator) }
  let(:credential) do
    create(:dossier_credential, user: charlie, title: "ISTQB Foundation",
                                files: [ fixture_file_upload("test_certificate.pdf", "application/pdf") ])
  end
  let(:file) { credential.files.first }
  let(:pdf)  { file_fixture("test_certificate.pdf").binread }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Serves its owner the certificate inline" do
      sign_in_as(charlie)
      get dossier_credential_file_path(credential, file)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to start_with("inline")
      expect(response.headers["Cache-Control"]).to include("private")
      expect(response.body.b).to eq(pdf.b)
    end

    it "Serves an admin the certificate" do
      sign_in_as(create(:user, :admin))
      get dossier_credential_file_path(credential, file)

      expect(response).to have_http_status(:ok)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Sends a visitor to sign in" do
      get dossier_credential_file_path(credential, file)
      expect(response).to redirect_to(new_session_path)
    end

    it "Returns Not Found to another Content Creator, even for an unrestricted Credential" do
      credential.update!(classification: "unrestricted")
      sign_in_as(create(:user, :content_creator))
      get dossier_credential_file_path(credential, file)

      expect(response).to have_http_status(:not_found)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Serves an image certificate as an image" do
      credential.files.attach(fixture_file_upload("test_image.png", "image/png"))
      image = credential.files.find { |f| f.filename.to_s == "test_image.png" }
      sign_in_as(charlie)
      get dossier_credential_file_path(credential, image)

      expect(response.media_type).to eq("image/png")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Returns Not Found for a file that belongs to another Credential" do
      other = create(:dossier_credential, user: charlie, files: [ fixture_file_upload("test_image.png", "image/png") ])
      sign_in_as(charlie)
      get dossier_credential_file_path(credential, other.files.first)

      expect(response).to have_http_status(:not_found)
    end
  end
end
