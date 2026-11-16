import { Controller } from "@hotwired/stimulus"

// Keeps a "quick period" select and two date fields in step:
// picking a period fills the dates, editing a date switches the period to "custom".
export default class extends Controller {
  static targets = ["period", "from", "to"]
  static values = { ranges: Object }

  pick() {
    const range = this.rangesValue[this.periodTarget.value]
    if (!range) return
    this.fromTarget.value = range[0]
    this.toTarget.value = range[1]
  }

  custom() {
    this.periodTarget.value = "custom"
  }
}
