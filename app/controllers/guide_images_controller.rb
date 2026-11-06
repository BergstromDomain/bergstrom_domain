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
  before_action :resume_session_if_present

  ROOT = Rails.root.join("docs/user-guide")

  def show
    image = ROOT.glob("*/images/*.png").find { |file| file == ROOT.join(params[:app], "images", "#{params[:name]}.png") }
    return head :not_found unless image && (!restricted? || current_user&.system_admin?)

    # A system-admin-only screenshot mustn't sit in a shared cache.
    public = !restricted?
    expires_in 1.hour, public: public
    send_file image, type: "image/png", disposition: "inline" if stale?(etag: Digest::SHA256.file(image).hexdigest, public: public)
  end

  private

  # Image folders are named after the app (docs/user-guide/cookbook), not
  # the section enum (recipes), but docs/user-guide/admin matches its
  # system-admin-only section.
  def restricted?
    GuidePage::SYSTEM_ADMIN_SECTIONS.include?(params[:app])
  end

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end
end
