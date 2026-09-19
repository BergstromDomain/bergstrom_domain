# app/models/session.rb
class Session < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :user

  # Called on every request (Navigable#set_left_nav) — forces the left nav
  # visible again whenever the app/page context changes, so hiding it can
  # never strand the user with no way to navigate elsewhere. A repeat
  # request for the same section leaves the current visibility alone,
  # which is what lets an explicit hide survive multiple page loads within
  # one app/section.
  def sync_left_nav_section!(section)
    section = section.to_s
    return if section == left_nav_section

    update!(left_nav_section: section, left_nav_visible: true)
  end

  def toggle_left_nav_visibility!
    update!(left_nav_visible: !left_nav_visible)
  end

  def left_nav_section_collapsed?(key)
    collapsed_nav_sections.include?(key)
  end

  def toggle_left_nav_section!(key)
    if left_nav_section_collapsed?(key)
      update!(collapsed_nav_sections: collapsed_nav_sections - [ key ])
    else
      update!(collapsed_nav_sections: collapsed_nav_sections + [ key ])
    end
  end
end
