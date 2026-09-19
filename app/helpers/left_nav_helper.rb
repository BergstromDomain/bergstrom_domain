# app/helpers/left_nav_helper.rb
module LeftNavHelper
  # Namespaces a per-H2 collapse key by the current app/section
  # (@left_nav_section) so the same subkey (e.g. "views") never collides
  # between apps — "event_tracker:views" and "blog_posts:views" collapse
  # independently. See Session#collapsed_nav_sections.
  def left_nav_section_key(subkey)
    "#{@left_nav_section}:#{subkey}"
  end

  def left_nav_section_collapsed?(subkey)
    return false unless Current.session

    Current.session.left_nav_section_collapsed?(left_nav_section_key(subkey))
  end

  # Renders the chevron-up/chevron-down toggle button for one left-nav-h2 —
  # both icons are always rendered; application.css shows only the one
  # matching .left-nav-section--collapsed, so no client-side icon swap is
  # needed. Guests get nothing (no Session to persist a toggle to).
  def left_nav_section_toggle(subkey, testid)
    return "".html_safe unless Current.session

    key = left_nav_section_key(subkey)
    collapsed = left_nav_section_collapsed?(subkey)

    content_tag(:button, type: "button", class: "left-nav-h2__toggle",
      data: { action: "left-nav#toggleSection", left_nav_key_param: key, testid: "#{testid}-toggle" },
      aria: { expanded: !collapsed }) do
      safe_join([
        lucide_icon("chevron-up", size: 14, class: "left-nav-h2__chevron-up"),
        lucide_icon("chevron-down", size: 14, class: "left-nav-h2__chevron-down")
      ])
    end
  end
end
