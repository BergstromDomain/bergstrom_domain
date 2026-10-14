# app/controllers/guide_images_controller.rb

# Serves the User Guide's screenshots from docs/user-guide/<app>/images/,
# where they're committed beside the Markdown that shows them (and so ship in
# the Docker image). GuidePageLoader points each page's images here. Served
# by Rails rather than as assets: adding docs/user-guide to the asset paths
# would also publish the raw .md files. Only PNGs that exist in an images
# folder are served — the file is picked from that list, never built from
# the request.
class GuideImagesController < ApplicationController
  allow_unauthenticated_access only: :show

  ROOT = Rails.root.join("docs/user-guide")

  def show
    image = ROOT.glob("*/images/*.png").find { |file| file == ROOT.join(params[:app], "images", "#{params[:name]}.png") }
    return head :not_found unless image

    expires_in 1.hour, public: true
    send_file image, type: "image/png", disposition: "inline" if stale?(etag: Digest::SHA256.file(image).hexdigest, public: true)
  end
end
