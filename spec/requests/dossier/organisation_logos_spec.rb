# spec/requests/dossier/organisation_logos_spec.rb
require "rails_helper"

# Who may set an Organisation's logo, straight at the URLs: whoever may
# create or update the Organisation, as for its other fields.
RSpec.describe "Dossier Organisation logos", type: :request do
  let(:charlie) { create(:user, :content_creator) }
  let(:uno)     { create(:user) }
  let(:adam)    { create(:user, :admin) }
  let(:qpt)     { create(:dossier_organisation, name: "Queensland Public Trustee") }
  let(:logo)    { fixture_file_upload("test_image.png", "image/png") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Lets Adam Admin set the logo of an existing Organisation" do
      sign_in_as(adam)
      patch dossier_organisation_path(qpt), params: { dossier_organisation: { logo: logo } }

      expect(response).to redirect_to(dossier_organisation_path(qpt))
      expect(qpt.reload.logo).to be_attached
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Won't let Charlie change the logo of an existing Organisation" do
      sign_in_as(charlie)
      patch dossier_organisation_path(qpt), params: { dossier_organisation: { logo: logo } }

      expect(response).to redirect_to(dossier_organisations_path)
      expect(qpt.reload.logo).not_to be_attached
    end

    it "Won't let Uno create an Organisation with a logo" do
      sign_in_as(uno)
      post dossier_organisations_path, params: { dossier_organisation: { name: "QPT", logo: logo } }

      expect(Dossier::Organisation.count).to eq(0)
    end

    it "Sends Gary to sign in to set a logo" do
      patch dossier_organisation_path(qpt), params: { dossier_organisation: { logo: logo } }

      expect(response).to redirect_to(new_session_path)
      expect(qpt.reload.logo).not_to be_attached
    end
  end
end
