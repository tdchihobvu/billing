import { Controller } from "@hotwired/stimulus"

// Role editor. Each area has an access level (No access / View only / Full access / Custom)
// that sets its switches in one click; Custom shows the individual switches. Also keeps the
// counts up to date and filters the "Add people" list.
export default class extends Controller {
  static targets = ["box", "level", "list", "groupCount", "total", "person", "query"]

  connect() {
    this.refresh()
  }

  boxesIn(group) {
    return this.boxTargets.filter((b) => b.dataset.group === group)
  }

  levelOf(group) {
    const boxes = this.boxesIn(group)
    const on = boxes.filter((b) => b.checked)
    const views = boxes.filter((b) => b.dataset.view === "true")
    if (on.length === 0) return "none"
    if (on.length === boxes.length) return "full"
    if (views.length && on.length === views.length && on.every((b) => b.dataset.view === "true")) return "view"
    return "custom"
  }

  groups() {
    return [...new Set(this.boxTargets.map((b) => b.dataset.group))]
  }

  refresh() {
    const boxes = this.boxTargets
    if (this.hasTotalTarget) this.totalTarget.textContent = `${boxes.filter((b) => b.checked).length} of ${boxes.length}`

    this.groups().forEach((group) => {
      const level = this.levelOf(group)
      this.levelTargets.filter((b) => b.dataset.group === group).forEach((button) => {
        button.setAttribute("aria-pressed", String(button.dataset.level === level))
      })
      const count = this.groupCountTargets.find((c) => c.dataset.group === group)
      const inGroup = this.boxesIn(group)
      if (count) count.textContent = `${inGroup.filter((b) => b.checked).length} of ${inGroup.length} allowed`
    })
  }

  setLevel(event) {
    const { group, level } = event.currentTarget.dataset
    const boxes = this.boxesIn(group)
    const list = this.listTargets.find((l) => l.dataset.group === group)
    if (level === "none") boxes.forEach((b) => { b.checked = false })
    if (level === "full") boxes.forEach((b) => { b.checked = true })
    if (level === "view") boxes.forEach((b) => { b.checked = b.dataset.view === "true" })
    if (list) list.hidden = level !== "custom"
    this.refresh()
    if (level === "custom" && list) list.querySelector("input")?.focus()
  }

  toggleList(event) {
    const list = this.listTargets.find((l) => l.dataset.group === event.currentTarget.dataset.group)
    if (list) list.hidden = !list.hidden
  }

  filterPeople() {
    const term = this.queryTarget.value.trim().toLowerCase()
    this.personTargets.forEach((row) => {
      row.hidden = term !== "" && !row.dataset.search.includes(term)
    })
  }
}
