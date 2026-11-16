import { Controller } from "@hotwired/stimulus"

// Sign-in helpers: show/hide the password and warn when Caps Lock is on.
export default class extends Controller {
  static targets = ["password", "toggle", "caps"]

  toggle() {
    const showing = this.passwordTarget.type === "text"
    this.passwordTarget.type = showing ? "password" : "text"
    this.toggleTarget.setAttribute("aria-pressed", String(!showing))
    this.toggleTarget.setAttribute("aria-label", showing ? "Show password" : "Hide password")
    this.toggleTarget.querySelector("i").className = showing ? "far fa-eye" : "far fa-eye-slash"
    this.passwordTarget.focus()
  }

  caps(event) {
    if (!this.hasCapsTarget || typeof event.getModifierState !== "function") return
    this.capsTarget.hidden = !event.getModifierState("CapsLock")
  }

  hideCaps() {
    if (this.hasCapsTarget) this.capsTarget.hidden = true
  }
}
