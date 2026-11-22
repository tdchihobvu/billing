import { Controller } from "@hotwired/stimulus"

// Licence invoice form: loads the chosen client's vehicles as tick boxes, and keeps
// "No. of Licenses" equal to the number of vehicles ticked (one licence per vehicle).
export default class extends Controller {
  static targets = ["client", "category", "quantity", "counter"]
  static values = { url: String, license: String }

  reload() {
    const frame = document.getElementById("license_vehicles")
    if (!frame) return
    const client = this.hasClientTarget ? this.clientTarget.value : ""
    if (!client) {
      frame.removeAttribute("src")
      frame.innerHTML = '<div class="zvehbox"><p class="zvehnote">Choose the client to see their vehicles.</p></div>'
      return
    }
    const params = new URLSearchParams({ client_id: client })
    if (this.licenseValue) params.set("license_id", this.licenseValue)
    if (this.hasCategoryTarget && this.categoryTarget.value) params.set("category_id", this.categoryTarget.value)
    frame.src = `${this.urlValue}?${params}`
  }

  boxes() {
    return [...this.element.querySelectorAll('input[type="checkbox"][name="vehicle_ids[]"]')]
  }

  // On load the saved quantity is kept when nothing is ticked; when the person unticks
  // everything themselves, it goes back to 1.
  count(event) {
    const all = this.boxes()
    const ticked = all.filter((b) => b.checked).length
    const byHand = event && event.type !== "turbo:frame-load"
    if (this.hasQuantityTarget && (ticked > 0 || byHand)) this.quantityTarget.value = Math.max(ticked, 1)
    if (this.hasCounterTarget) this.counterTarget.textContent = `${ticked} of ${all.length} ticked`
  }

  all(event) {
    this.boxes().forEach((b) => { b.checked = true })
    this.count(event)
  }

  none(event) {
    this.boxes().forEach((b) => { b.checked = false })
    this.count(event)
  }
}
