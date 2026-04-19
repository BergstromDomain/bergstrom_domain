// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this._handleOutsideClick = this._handleOutsideClick.bind(this)
  }

  toggle() {
    const isOpen = this.menuTarget.classList.contains("dropdown--open")
    this._closeAll()
    if (!isOpen) {
      this.menuTarget.classList.add("dropdown--open")
      document.addEventListener("click", this._handleOutsideClick)
    }
  }

  close() {
    this.menuTarget.classList.remove("dropdown--open")
    document.removeEventListener("click", this._handleOutsideClick)
  }

  _closeAll() {
    document.querySelectorAll(".dropdown__menu.dropdown--open").forEach(menu => {
      menu.classList.remove("dropdown--open")
    })
    document.removeEventListener("click", this._handleOutsideClick)
  }

  _handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}