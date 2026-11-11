# app/controllers/dossier/contribution_files_controller.rb

# Serves a Contribution's files (posters, slides) to its owner and admins
# only, whatever its classification, as Credentials' certificates are. Pages
# link here, never to Active Storage's own (unauthenticated) blob URLs.
class Dossier::ContributionFilesController < ApplicationController
  def show
    contribution = Dossier::Contribution.find_by(id: params[:contribution_id])
    return head :not_found unless contribution&.files_visible_to?(current_user)

    file = contribution.files.find_by(id: params[:id])
    return head :not_found unless file

    response.headers["Cache-Control"] = "private, no-store"
    send_data file.download, filename: file.filename.to_s, type: file.content_type, disposition: "inline"
  end
end
