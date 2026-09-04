// app/javascript/controllers/comment_toggle_controller.js
import { Controller } from "@hotwired/stimulus"

// Minimal show/hide for a comment's Reply/Edit form — no outside-click
// handling needed here (unlike dropdown_controller.js), just a plain toggle.
export default class extends Controller {
  static targets = ["form"]

  toggle() {
    this.formTarget.hidden = !this.formTarget.hidden
  }
}
