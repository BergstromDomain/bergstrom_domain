// app/javascript/controllers/blog_post_editor_controller.js
import { Controller } from "@hotwired/stimulus"
import Quill from "quill"

// `body` is stored as Markdown, always. The Raw textarea holds that
// canonical value directly; the Formatted tab is a Quill instance that only
// gets synced against it at tab-switch/submit boundaries (via the server-side
// #convert_format endpoint), not continuously — see Block 2's design notes.
export default class extends Controller {
  static targets = [
    "raw", "editor", "format",
    "rawPanel", "formattedPanel",
    "rawTab", "formattedTab"
  ]
  static values = { convertUrl: String }

  connect() {
    this.quill = new Quill(this.editorTarget, {
      theme: "snow",
      modules: {
        toolbar: [
          [{ header: [ 1, 2, 3, false ] }],
          [ "bold", "italic", "underline", "strike" ],
          [ "blockquote" ],
          [{ list: "ordered" }, { list: "bullet" }],
          [ "link" ],
          [ "clean" ]
        ]
      }
    })

    this.submitting = false
    this.submitHandler = (event) => this.handleSubmit(event)
    this.element.addEventListener("submit", this.submitHandler)

    this.activatePanel({ formatted: this.formatTarget.value === "formatted" })
  }

  disconnect() {
    this.element.removeEventListener("submit", this.submitHandler)
  }

  async switchToFormatted() {
    const html = await this.convert("markdown", this.rawTarget.value)
    this.quill.setText("")
    this.quill.clipboard.dangerouslyPasteHTML(html || "")
    this.activatePanel({ formatted: true })
  }

  async switchToRaw() {
    const markdown = await this.convert("html", this.quill.root.innerHTML)
    this.rawTarget.value = markdown || ""
    this.activatePanel({ formatted: false })
  }

  activatePanel({ formatted }) {
    this.formatTarget.value = formatted ? "formatted" : "raw"
    this.formattedPanelTarget.hidden = !formatted
    this.rawPanelTarget.hidden = formatted
    this.formattedTabTarget.classList.toggle("tab--active", formatted)
    this.rawTabTarget.classList.toggle("tab--active", !formatted)
  }

  async handleSubmit(event) {
    if (this.submitting) return
    if (this.formatTarget.value !== "formatted") return

    event.preventDefault()
    const markdown = await this.convert("html", this.quill.root.innerHTML)
    this.rawTarget.value = markdown || ""
    this.submitting = true
    this.element.requestSubmit()
  }

  async convert(source, content) {
    const headers = { "Content-Type": "application/json", "Accept": "application/json" }
    // Absent (not just empty) when forgery protection is off, e.g. in the
    // test environment — guard rather than let a null dereference here
    // silently abort the submit this runs inside of.
    const csrfTag = document.querySelector('meta[name="csrf-token"]')
    if (csrfTag) headers["X-CSRF-Token"] = csrfTag.content

    const response = await fetch(this.convertUrlValue, {
      method: "POST",
      headers,
      body: JSON.stringify({ source, content })
    })

    if (!response.ok) return content
    const data = await response.json()
    return source === "markdown" ? data.html : data.markdown
  }
}
