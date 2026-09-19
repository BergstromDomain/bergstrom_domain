// app/javascript/controllers/popup_controller.js
import { Controller } from "@hotwired/stimulus"

// Generic open/close mechanics for a native <dialog>-based popup — no
// Likes-specific (or any other feature's) content. A caller wraps its own
// trigger element and a dialog (data-popup-target="dialog") in one
// data-controller="popup" container; this controller only handles
// showModal()/close(), Esc, backdrop-click dismissal, and returning focus
// to whatever triggered it — see confirm_dialog_controller.js for the same
// dismissal conventions on a single-instance, promise-based dialog.
export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    this.dialogTarget.addEventListener("cancel", this._handleNativeCancel)
    this.dialogTarget.addEventListener("click", this._handleBackdropClick)
  }

  disconnect() {
    this.dialogTarget.removeEventListener("cancel", this._handleNativeCancel)
    this.dialogTarget.removeEventListener("click", this._handleBackdropClick)
  }

  open() {
    if (this.dialogTarget.open) return

    this._triggerElement = document.activeElement
    this.dialogTarget.showModal()
  }

  close() {
    if (!this.dialogTarget.open) return
    this.dialogTarget.close()

    const trigger = this._triggerElement
    this._triggerElement = null
    if (trigger && typeof trigger.focus === "function") trigger.focus()
  }

  _handleNativeCancel = (event) => {
    event.preventDefault()
    this.close()
  }

  _handleBackdropClick = (event) => {
    if (event.target === this.dialogTarget) this.close()
  }
}
