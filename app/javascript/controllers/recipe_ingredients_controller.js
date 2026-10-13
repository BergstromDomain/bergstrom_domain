// app/javascript/controllers/recipe_ingredients_controller.js
import { Controller } from "@hotwired/stimulus"

// The Recipe form's two-level ingredient lists: lists (sections), each with
// its own rows. New ones are cloned from <template>s with a unique index
// swapped in for the NEW_SECTION / NEW_INGREDIENT placeholders (the same
// approach as social_media_accounts_controller.js). Removing a never-saved
// list or row just deletes it from the page; a saved one is hidden and its
// `_destroy` field set, so the server deletes it on save.
export default class extends Controller {
  static targets = ["sections", "sectionTemplate"]

  addSection(event) {
    event.preventDefault()
    const html = this.sectionTemplateTarget.innerHTML.replace(/NEW_SECTION/g, this.uniqueIndex())
    this.sectionsTarget.insertAdjacentHTML("beforeend", html)
  }

  removeSection(event) {
    event.preventDefault()
    this.discard(event.target.closest("[data-recipe-ingredients-target='section']"))
  }

  addIngredient(event) {
    event.preventDefault()
    const section = event.target.closest("[data-recipe-ingredients-target='section']")
    const template = section.querySelector(":scope > [data-recipe-ingredients-target='rowTemplate']")
    const html = template.innerHTML.replace(/NEW_INGREDIENT/g, this.uniqueIndex())
    section.querySelector(":scope > [data-recipe-ingredients-target='rows']").insertAdjacentHTML("beforeend", html)
  }

  removeIngredient(event) {
    event.preventDefault()
    this.discard(event.target.closest(".ingredient-row"))
  }

  discard(element) {
    const destroy = element.querySelector(":scope [data-recipe-ingredients-target='destroy']")
    if (destroy && destroy.closest(".ingredient-section, .ingredient-row") === element) {
      destroy.value = "1"
      element.style.display = "none"
    } else {
      element.remove()
    }
  }

  uniqueIndex() {
    this.counter = (this.counter || 0) + 1
    return `${Date.now()}${this.counter}`
  }
}
