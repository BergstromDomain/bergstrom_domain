// app/javascript/controllers/social_media_accounts_controller.js
import { Controller } from "@hotwired/stimulus"

// Repeatable Social Media Platform + username rows on the Person edit form.
// Existing (persisted) rows are removed via a plain `_destroy` checkbox —
// no JS required for the removal itself to actually work, it's a normal
// form submit. toggleRemoved below is pure visual feedback on top of that:
// without JS the checkbox still gets submitted correctly, it just won't
// disappear from view until after the page reloads. Adding a new row does
// need JS: it clones the <template> with a unique index swapped in for the
// NEW_RECORD placeholder. A freshly added row has never been persisted, so
// removing it again is just deleting the DOM node — nothing needs to reach
// the server.
export default class extends Controller {
  static targets = ["container", "template"]

  add(event) {
    event.preventDefault()
    const index = new Date().getTime()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, index)
    this.containerTarget.insertAdjacentHTML("beforeend", html)
  }

  removeNewRow(event) {
    event.preventDefault()
    event.target.closest("[data-social-media-accounts-target='row']").remove()
  }

  toggleRemoved(event) {
    // Not the `hidden` attribute: .form-group--inline sets `display: flex`,
    // and that author rule wins over the UA stylesheet's `[hidden] {
    // display: none }`, so `hidden` alone is silently a no-op here.
    const row = event.target.closest("[data-social-media-accounts-target='row']")
    row.style.display = event.target.checked ? "none" : ""
  }
}
