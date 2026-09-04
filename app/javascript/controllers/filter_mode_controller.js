// app/javascript/controllers/filter_mode_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["basicTab", "sqlTab", "basicPanel", "sqlPanel", "mode"]

  connect() {
    this.activatePanel({ sql: this.modeTarget.value === "sql" })
  }

  switchToBasic() {
    this.activatePanel({ sql: false })
  }

  switchToSql() {
    this.activatePanel({ sql: true })
  }

  activatePanel({ sql }) {
    this.modeTarget.value = sql ? "sql" : "basic"
    this.sqlPanelTarget.hidden = !sql
    this.basicPanelTarget.hidden = sql
    this.sqlTabTarget.classList.toggle("tab--active", sql)
    this.basicTabTarget.classList.toggle("tab--active", !sql)
  }
}
