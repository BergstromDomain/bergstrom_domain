// app/javascript/controllers/left_nav_controller.js
import { Controller } from "@hotwired/stimulus"

// Instant client-side toggle for the left nav's visibility, persisted in the
// background to the current Session so it survives the rest of the login
// session (see Session#left_nav_visible). Lives on .site-shell (not
// .left-nav itself) so the same collapsed-state class can also drive the
// footer's indent via CSS — see application.css.
export default class extends Controller {
  static targets = [ "content" ]
  static values = { toggleVisibilityUrl: String, toggleSectionUrl: String }

  connect() {
    // Lets a (JS) test deterministically wait for a background persist to
    // finish (e.g. before reloading the page) instead of racing a fetch —
    // same purpose as confirm_dialog_controller.js's data-ready flag.
    this.element.dataset.leftNavSyncing = "false"
  }

  showNav() {
    this.element.classList.remove("site-shell--nav-collapsed")
    if (this.hasContentTarget) this.contentTarget.removeAttribute("aria-hidden")
    this._patch(this.toggleVisibilityUrlValue)
  }

  hideNav() {
    this.element.classList.add("site-shell--nav-collapsed")
    if (this.hasContentTarget) this.contentTarget.setAttribute("aria-hidden", "true")
    this._patch(this.toggleVisibilityUrlValue)
  }

  // Each left-nav-h2's own toggle button carries its section key as a
  // Stimulus param (data-left-nav-key-param) — one controller instance on
  // .site-shell handles every section via plain DOM traversal from
  // whichever button was actually clicked, rather than a target per section.
  toggleSection(event) {
    const section = event.currentTarget.closest(".left-nav-section")
    const collapsed = section.classList.toggle("left-nav-section--collapsed")

    const body = section.querySelector(".left-nav-section__body")
    if (body) body.setAttribute("aria-hidden", collapsed ? "true" : "false")
    event.currentTarget.setAttribute("aria-expanded", (!collapsed).toString())

    this._patch(this.toggleSectionUrlValue, { key: event.params.key })
  }

  async _patch(url, params = {}) {
    this.element.dataset.leftNavSyncing = "true"

    const headers = { Accept: "application/json" }
    const csrfTag = document.querySelector('meta[name="csrf-token"]')
    if (csrfTag) headers["X-CSRF-Token"] = csrfTag.content

    const query = new URLSearchParams(params).toString()
    const target = query ? `${url}?${query}` : url

    try {
      // keepalive lets this request survive a navigation started right
      // after the click (these toggle buttons don't navigate themselves,
      // but a user can immediately click a nav link afterwards) — without
      // it, the browser can abort an in-flight fetch on page unload and
      // silently drop the toggle.
      await fetch(target, { method: "PATCH", headers, keepalive: true })
    } finally {
      this.element.dataset.leftNavSyncing = "false"
    }
  }
}
