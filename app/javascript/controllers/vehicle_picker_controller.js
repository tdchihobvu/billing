import { Controller } from "@hotwired/stimulus"

// Licence invoice form: loads the chosen client's vehicles as tick boxes, and keeps
// "No. of Licenses" equal to the number of vehicles ticked (one licence per vehicle).
export default class extends Controller {
  static targets = ["client", "category", "quantity"]
  static values = { url: String, license: String }

  reload() {
    const frame = document.getElementById("license_vehicles")
    if (!frame) return
    const client = this.hasClientTarget ? this.clientTarget.value : ""
    if (!client) {
      frame.removeAttribute("src")
      frame.innerHTML = '<p class="zhint" style="margin:0">Choose the client to see their vehicles.</p>'
      return
    }
    const params = new URLSearchParams({ client_id: client })
    if (this.licenseValue) params.set("license_id", this.licenseValue)
    if (this.hasCategoryTarget && this.categoryTarget.value) params.set("category_id", this.categoryTarget.value)
    frame.src = `${this.urlValue}?${params}`
  }

  count() {
    const ticked = this.element.querySelectorAll('input[type="checkbox"][name="vehicle_ids[]"]:checked').length
    if (ticked > 0 && this.hasQuantityTarget) this.quantityTarget.value = ticked
  }
}
