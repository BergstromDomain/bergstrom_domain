# app/helpers/guide_pages_helper.rb
module GuidePagesHelper
  # The guide pages in one app section the current visitor may read, in
  # reading order (see GuidePage.in_reading_order) — builds
  # both the per-app left-nav "How To" table of contents (Occasions/
  # Chronicle) and the full contents tree on the dedicated Guide Pages nav
  # section.
  def guide_pages_for_section(app_section)
    GuidePage.visible_to(current_user).where(app_section: app_section).in_reading_order
  end

  # [label, value] pairs for the App Section dropdown — only sections the
  # writer may read, so an admin can't file a page where they'd lose it.
  def guide_page_app_section_options
    GuidePage.sections_visible_to(current_user).map { |key| [ GuidePage::APP_SECTION_LABELS.fetch(key), key ] }
  end
end
