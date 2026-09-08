// app/javascript/controllers/social_media_accounts_controller.js
import { Controller } from "@hotwired/stimulus"

// Repeatable Social Media Platform + username rows on the Person edit form.
// Existing (persisted) rows are removed via a plain `_destroy` checkbox —
// no JS required for that, it's a normal form submit. Only adding a new
// row needs JS: it clones the <template> with a unique index swapped in
// for the NEW_RECORD placeholder. A freshly added row has never been
// persisted, so removing it again is just deleting the DOM node — nothing
// needs to reach the server.
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
}
