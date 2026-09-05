// app/javascript/controllers/toast_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { dismissAfter: Number }

  connect() {
    if (this.hasDismissAfterValue) {
      this._timeout = setTimeout(() => this.dismiss(), this.dismissAfterValue)
    }
  }

  disconnect() {
    clearTimeout(this._timeout)
  }

  dismiss() {
    clearTimeout(this._timeout)
    this.element.remove()
  }
}
