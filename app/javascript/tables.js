import DataTable from "datatables.net-bs5"

// Enhances the ordinary tables that hold all their rows in the page.
const plainTables = () => document.querySelectorAll("table#dataTable:not([data-controller])")

document.addEventListener("turbo:load", () => {
  plainTables().forEach((table) => {
    if (!DataTable.isDataTable(table)) new DataTable(table)
  })
})

// Turbo caches the page before leaving it, so restore the original table.
document.addEventListener("turbo:before-cache", () => {
  plainTables().forEach((table) => {
    if (DataTable.isDataTable(table)) new DataTable(table).destroy()
  })
})
