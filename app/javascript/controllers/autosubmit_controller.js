import { Controller } from "@hotwired/stimulus"

// Submits a search form while the user types (after a short pause), so results appear without pressing Search.
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 }, minimum: { type: Number, default: 2 } }

  queue(event) {
    clearTimeout(this.timer)
    const length = event.target.value.trim().length
    if (length > 0 && length < this.minimumValue) return
    this.timer = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
