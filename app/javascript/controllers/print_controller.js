// app/javascript/controllers/print_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  trigger() {
    window.print()
  }
}
