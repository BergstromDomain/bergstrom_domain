// app/javascript/controllers/confirm_dialog_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "message", "confirmButton", "cancelButton"]

  connect() {
    this._resolve = null
    this._triggerElement = null
    this.dialogTarget.addEventListener("cancel", this._handleNativeCancel)
    this.dialogTarget.addEventListener("click", this._handleBackdropClick)
  }

  disconnect() {
    this.dialogTarget.removeEventListener("cancel", this._handleNativeCancel)
    this.dialogTarget.removeEventListener("click", this._handleBackdropClick)
  }

  // Public API for the Turbo.config.forms.confirm override — opens the
  // dialog with the given message and resolves once the user answers.
  open(message) {
    if (this.dialogTarget.open) return Promise.resolve(false)

    return new Promise((resolve) => {
      this._resolve = resolve
      this._triggerElement = document.activeElement
      this.messageTarget.textContent = message
      this.dialogTarget.showModal()
    })
  }

  confirm() {
    this._settle(true)
  }

  cancel() {
    this._settle(false)
  }

  _handleNativeCancel = (event) => {
    event.preventDefault()
    this._settle(false)
  }

  _handleBackdropClick = (event) => {
    if (event.target === this.dialogTarget) this._settle(false)
  }

  _settle(result) {
    if (this.dialogTarget.open) this.dialogTarget.close()

    const resolve = this._resolve
    this._resolve = null

    const trigger = this._triggerElement
    this._triggerElement = null
    if (trigger && typeof trigger.focus === "function") trigger.focus()

    if (resolve) resolve(result)
  }
}
