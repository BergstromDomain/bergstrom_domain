# app/helpers/guide_pages_helper.rb
module GuidePagesHelper
  # All guide pages belonging to one app section, ordered by title — builds
  # both the per-app left-nav "How To" table of contents (Occasions/
  # Chronicle) and the full contents tree on the dedicated Guide Pages nav
  # section.
  def guide_pages_for_section(app_section)
    GuidePage.where(app_section: app_section).order(:title)
  end
end
