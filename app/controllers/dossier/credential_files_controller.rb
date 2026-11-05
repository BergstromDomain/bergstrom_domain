# app/controllers/dossier/credential_files_controller.rb

# Serves a Credential's certificate files to its owner and admins only,
# whatever the Credential's classification: scans can carry personal details.
# Pages link here, never to Active Storage's own (unauthenticated) blob URLs.
class Dossier::CredentialFilesController < ApplicationController
  def show
    credential = Dossier::Credential.find_by(id: params[:credential_id])
    return head :not_found unless credential&.files_visible_to?(current_user)

    file = credential.files.find_by(id: params[:id])
    return head :not_found unless file

    response.headers["Cache-Control"] = "private, no-store"
    send_data file.download, filename: file.filename.to_s, type: file.content_type, disposition: "inline"
  end
end
