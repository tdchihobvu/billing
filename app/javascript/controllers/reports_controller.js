import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reports"
export default class extends Controller {
  connect() {
    console.log('Connected !!!!')
  }
  initialize() {
    this.element.setAttribute("data-action","change->reports#loadList")
  }

  loadList() {
    const selectedClient = this.element.options[this.element.selectedIndex].value
    this.url = `/employee_tasks/filter_by_client?client_id=${selectedClient}`
    fetch(this.url,{
      headers: {
        Accept: "text/vnd.turbo-stream.html"
      }
    })
    .then(r => r.text())
    .then(html => Turbo.renderStreamMessage(html))
  }
}
