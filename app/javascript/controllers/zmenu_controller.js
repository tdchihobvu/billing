import { Controller } from "@hotwired/stimulus"

// The "More" menus: open on click, close on Escape or a click elsewhere.
export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.outside = (event) => { if (!this.element.contains(event.target)) this.close() }
    this.escape = (event) => { if (event.key === "Escape") { this.close(); this.buttonTarget.focus() } }
    document.addEventListener("click", this.outside)
    document.addEventListener("keydown", this.escape)
  }

  disconnect() {
    document.removeEventListener("click", this.outside)
    document.removeEventListener("keydown", this.escape)
  }

  toggle() {
    const open = this.menuTarget.hidden
    this.menuTarget.hidden = !open
    this.buttonTarget.setAttribute("aria-expanded", String(open))
    if (open) {
      const first = this.menuTarget.querySelector("a, button")
      if (first) first.focus()
    }
  }

  close() {
    this.menuTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }
}
