# spec/requests/dossier/contributions_spec.rb
require "rails_helper"

# Who may do what with a Contribution, straight at the URLs, and its files:
# served only to the owner and admins.
RSpec.describe "Dossier Contributions", type: :request do
  let(:charlie) { create(:user, :content_creator) }
  let(:talk) do
    create(:dossier_contribution, user: charlie, title: "Statistical Methods in Software Testing",
                                  files: [ fixture_file_upload("test_image.png", "image/png") ])
  end
  let(:attrs) { { dossier_contribution: { kind: "talk", title: "Changed", start_year: "2024", start_month_number: "11" } } }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Serves its owner a poster inline, privately" do
      sign_in_as(charlie)
      get dossier_contribution_file_path(talk, talk.files.first)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
      expect(response.headers["Content-Disposition"]).to start_with("inline")
      expect(response.headers["Cache-Control"]).to include("private")
    end

    it "Lets an admin update someone else's" do
      sign_in_as(create(:user, :admin))
      patch dossier_contribution_path(talk), params: attrs

      expect(response).to redirect_to(dossier_contribution_path(talk))
      expect(talk.reload.title).to eq("Changed")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Sends a visitor to sign in to add, change or delete one" do
      get new_dossier_contribution_path
      expect(response).to redirect_to(new_session_path)
      post dossier_contributions_path, params: attrs
      expect(response).to redirect_to(new_session_path)
      patch dossier_contribution_path(talk), params: attrs
      expect(response).to redirect_to(new_session_path)
      delete dossier_contribution_path(talk)
      expect(response).to redirect_to(new_session_path)
      expect(talk.reload).to have_attributes(title: "Statistical Methods in Software Testing", deleted_at: nil)
    end

    it "Won't let an app user add one" do
      sign_in_as(create(:user))
      get new_dossier_contribution_path
      expect(response).to redirect_to(dossier_path)
      expect { post dossier_contributions_path, params: attrs }.not_to change(Dossier::Contribution, :count)
    end

    it "Won't let another creator change, delete or restore Charlie's, even an Unrestricted one" do
      talk.update!(classification: "unrestricted")
      sign_in_as(create(:user, :content_creator))

      get edit_dossier_contribution_path(talk)
      expect(response).to redirect_to(dossier_contributions_path)
      patch dossier_contribution_path(talk), params: attrs
      delete dossier_contribution_path(talk)
      talk.update_columns(deleted_at: 1.day.ago)
      post restore_dossier_contribution_path(talk)
      expect(talk.reload).to have_attributes(title: "Statistical Methods in Software Testing")
      expect(talk.deleted_at).to be_present
    end

    it "Keeps the owner on Edit when a change isn't valid" do
      sign_in_as(charlie)
      patch dossier_contribution_path(talk), params: { dossier_contribution: { title: " ", url: "not-a-link" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Link must start with http:// or https://")
      expect(talk.reload.title).to eq("Statistical Methods in Software Testing")
    end

    it "Serves the files to no one else, even on an Unrestricted one" do
      talk.update!(classification: "unrestricted")
      get dossier_contribution_file_path(talk, talk.files.first)
      expect(response).to redirect_to(new_session_path)

      sign_in_as(create(:user, :content_creator))
      get dossier_contribution_file_path(talk, talk.files.first)
      expect(response).to have_http_status(:not_found)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Shows another creator an Unrestricted one, without its files" do
      talk.update!(classification: "unrestricted")
      sign_in_as(create(:user, :content_creator))
      get dossier_contribution_path(talk)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Statistical Methods in Software Testing")
      expect(response.body).not_to include(dossier_contribution_file_path(talk, talk.files.first))
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Won't show a Restricted or deleted one to anyone else, or anything to a visitor" do
      get dossier_contribution_path(talk)
      expect(response).to redirect_to(new_session_path)

      sign_in_as(create(:user, :content_creator))
      get dossier_contribution_path(talk)
      expect(response).to redirect_to(dossier_contributions_path)

      talk.update!(classification: "unrestricted")
      talk.soft_delete!
      get dossier_contribution_path(talk)
      expect(response).to have_http_status(:not_found)
    end

    it "Won't serve another Contribution's file through this one's URL" do
      other = create(:dossier_contribution, user: charlie, files: [ fixture_file_upload("test_image.jpg", "image/jpeg") ])
      sign_in_as(charlie)
      get dossier_contribution_file_path(talk, other.files.first)

      expect(response).to have_http_status(:not_found)
    end
  end
end
