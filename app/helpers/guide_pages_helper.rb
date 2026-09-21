# app/helpers/guide_pages_helper.rb
module GuidePagesHelper
  # Left-nav "User Guide" links point at the given app's own GuidePage once
  # an admin has created one, falling back to the shared /user_guide entry
  # point (which itself falls back further, see PagesController#user_guide)
  # while that section is still unwritten.
  def guide_page_link_for(app_section)
    page = GuidePage.find_by(app_section: app_section)
    page ? guide_page_path(page) : user_guide_path
  end
end
