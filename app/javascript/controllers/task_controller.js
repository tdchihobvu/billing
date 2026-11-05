import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = ["input","timer"]
  static values = { showIf: String }

  connect() {
    this.timerTarget.hidden = true
  }

  // toggle() {
  //   if (this.inputTarget.value != this.showIfValue) {
  //     this.outputTarget.hidden = true
  //   } else if (this.inputTarget.value = this.showIfValue) {
  //     this.outputTarget.hidden = false
  //   }
  // }
  
}
