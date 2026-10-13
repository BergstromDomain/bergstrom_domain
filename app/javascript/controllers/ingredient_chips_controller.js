// app/javascript/controllers/ingredient_chips_controller.js
import { Controller } from "@hotwired/stimulus"

// Find Recipes By Ingredients: Enter or a comma turns the typed text into a
// chip (a hidden ingredients[] field), and adding or removing a chip
// resubmits the form into the results frame. Without JavaScript the text box
// and Find Recipes button submit as a plain form instead.
export default class extends Controller {
  static targets = ["list", "input", "submit", "template", "value", "label", "remove"]

  connect() {
    // Only the chips are submitted from here on.
    this.inputTarget.removeAttribute("name")
    this.submitTarget.hidden = true
  }

  keydown(event) {
    if (event.key === "Enter" || event.key === ",") {
      event.preventDefault()
      this.addChips(this.inputTarget.value)
    }
  }

  // Catches a pasted "chicken, garlic".
  input() {
    if (this.inputTarget.value.includes(",")) this.addChips(this.inputTarget.value)
  }

  remove(event) {
    event.currentTarget.closest(".ingredient-chip").remove()
    this.element.requestSubmit()
  }

  addChips(text) {
    const existing = this.valueTargets.map((field) => field.value.toLowerCase())
    const terms = text.split(",").map((term) => term.trim().replace(/\s+/g, " ")).filter(Boolean)
    let added = false

    terms.forEach((term) => {
      if (existing.includes(term.toLowerCase())) return
      existing.push(term.toLowerCase())
      this.listTarget.appendChild(this.buildChip(term))
      added = true
    })

    this.inputTarget.value = ""
    if (added) this.element.requestSubmit()
  }

  buildChip(term) {
    const chip = this.templateTarget.content.firstElementChild.cloneNode(true)
    chip.querySelector("input").value = term
    chip.querySelector("[data-ingredient-chips-target='label']").textContent = term
    const button = chip.querySelector("button")
    button.setAttribute("aria-label", `Remove ${term}`)
    button.dataset.testid = `ingredient-chip-remove-${this.parameterize(term)}`
    return chip
  }

  parameterize(term) {
    return term.toLowerCase().normalize("NFKD").replace(/[̀-ͯ]/g, "")
      .replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
  }
}
