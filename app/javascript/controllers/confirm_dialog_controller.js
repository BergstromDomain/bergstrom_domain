// app/javascript/controllers/confirm_dialog_controller.js
import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["dialog", "message", "detail", "confirmButton", "cancelButton"]

  connect() {
    this._resolve = null
    this._triggerElement = null
    this.dialogTarget.addEventListener("cancel", this._handleNativeCancel)
    this.dialogTarget.addEventListener("click", this._handleBackdropClick)

    Turbo.config.forms.confirm = (message) => this.open(message)

    // Signals, for tests, that the Turbo.config.forms.confirm override above
    // has actually been registered — the dialog's markup is present in
    // server-rendered HTML immediately, well before Stimulus/Turbo finish
    // loading and connecting on a slow/cold boot, so a click that races
    // ahead of this would fall through to an unintercepted native form
    // submit instead of triggering the dialog at all.
    this.element.dataset.ready = "true"
  }

  disconnect() {
    this.dialogTarget.removeEventListener("cancel", this._handleNativeCancel)
    this.dialogTarget.removeEventListener("click", this._handleBackdropClick)
  }

  // Public API for the Turbo.config.forms.confirm override — opens the
  // dialog with the given message and resolves once the user answers.
  open(message) {
    if (this.dialogTarget.open) return Promise.resolve(false)

    const [question, detail] = this._splitMessage(message)

    return new Promise((resolve) => {
      this._resolve = resolve
      this._triggerElement = document.activeElement
      this.messageTarget.textContent = question
      this.detailTarget.textContent = detail
      this.detailTarget.hidden = detail.length === 0
      this.dialogTarget.showModal()
    })
  }

  // Splits "Delete Bob? This cannot be undone." into a question row and a
  // detail row at the first sentence break, so every existing
  // data-turbo-confirm message renders as two rows without call sites
  // needing to change. Messages with no second sentence (e.g. "Suspend
  // Bob?") render as a single row — detail comes back empty.
  _splitMessage(message) {
    const match = message.match(/^(.*?[.!?])\s*(.*)$/)
    if (!match || match[2].length === 0) return [message, ""]

    return [match[1], match[2]]
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
