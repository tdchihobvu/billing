import { Controller } from "@hotwired/stimulus"
import DataTable from "datatables.net-bs5"

// Connects to data-controller="server-table" on an element wrapping the table.
// DataTables moves the table in the page, which would disconnect a controller on
// the table itself and rebuild it forever.
export default class extends Controller {
  static targets = ["table"]
  static values = { url: String, order: { type: Array, default: [] } }

  connect() {
    const columns = Array.from(this.tableTarget.querySelectorAll("thead th"), (th) => ({
      orderable: th.dataset.sortable !== "false"
    }))

    this.table = new DataTable(this.tableTarget, {
      serverSide: true,
      processing: true,
      searchDelay: 300,
      pageLength: 25,
      ajax: { url: this.urlValue },
      order: this.orderValue,
      columns
    })

    this.teardown = this.teardown.bind(this)
    document.addEventListener("turbo:before-cache", this.teardown)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.teardown)
    this.teardown()
  }

  teardown() {
    if (this.table) this.table.destroy()
    this.table = null
  }
}
