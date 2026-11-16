import { Controller } from "@hotwired/stimulus"

// Filters the users list by role (tabs) and by a search box, without reloading.
export default class extends Controller {
  static targets = ["tab", "query", "person", "group", "showing", "empty"]

  connect() {
    this.role = this.data.get("role") || "all"
    this.apply()
  }

  selectRole(event) {
    event.preventDefault()
    this.role = event.currentTarget.dataset.role
    const url = new URL(window.location)
    if (this.role === "all") url.searchParams.delete("role")
    else url.searchParams.set("role", this.role)
    window.history.replaceState(window.history.state, "", url)
    this.apply()
  }

  apply() {
    const term = (this.hasQueryTarget ? this.queryTarget.value : "").trim().toLowerCase()
    let shown = 0

    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.role === this.role
      tab.classList.toggle("is-active", active)
      tab.setAttribute("aria-pressed", active)
    })

    this.personTargets.forEach((row) => {
      const roleOk = this.role === "all" || row.dataset.role === this.role
      const textOk = !term || row.dataset.search.includes(term)
      row.hidden = !(roleOk && textOk)
      if (!row.hidden) shown++
    })

    this.groupTargets.forEach((group) => {
      group.hidden = !group.querySelector("[data-people-filter-target='person']:not([hidden])")
    })

    if (this.hasShowingTarget) {
      const total = this.personTargets.length
      this.showingTarget.textContent = shown === total ? `${total} people` : `Showing ${shown} of ${total}`
    }
    if (this.hasEmptyTarget) this.emptyTarget.hidden = shown > 0
  }
}
