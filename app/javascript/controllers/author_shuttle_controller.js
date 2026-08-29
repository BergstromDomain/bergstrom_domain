// app/javascript/controllers/author_shuttle_controller.js
import { Controller } from "@hotwired/stimulus"

// A dual-listbox "shuttle": options move freely between the Available and
// Selected <select multiple> boxes by clicking, so neither box's native
// highlight state is meaningful — only which box an option currently lives
// in matters. All options in the Selected box are marked `.selected` right
// before submit (the only moment it matters for a <select multiple>), not
// continuously, so clicking an option to choose it for a move doesn't fight
// with that.
export default class extends Controller {
  static targets = ["available", "selected", "filter"]

  connect() {
    this.submitHandler = () => this.selectAllBeforeSubmit()
    this.element.addEventListener("submit", this.submitHandler)
  }

  disconnect() {
    this.element.removeEventListener("submit", this.submitHandler)
  }

  add() {
    this.move(this.availableTarget, this.selectedTarget)
  }

  remove() {
    this.move(this.selectedTarget, this.availableTarget)
  }

  move(from, to) {
    Array.from(from.selectedOptions).forEach((option) => {
      option.selected = false
      to.appendChild(option)
    })
  }

  filter() {
    const query = this.filterTarget.value.trim().toLowerCase()
    Array.from(this.availableTarget.options).forEach((option) => {
      option.hidden = query.length > 0 && !option.text.toLowerCase().includes(query)
    })
  }

  selectAllBeforeSubmit() {
    Array.from(this.selectedTarget.options).forEach((option) => { option.selected = true })
  }
}
