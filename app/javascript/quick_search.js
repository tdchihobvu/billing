// The Ctrl+K search box. Pages come from the menu, so people only see pages
// their company has switched on. Clients and invoices come from the server.
const SEARCH_DELAY_MS = 180
const MINIMUM_SERVER_TERM = 2

let timer = null
let request = null

const dialog = () => document.getElementById("quickSearch")
const input = () => dialog().querySelector("input")
const results = () => dialog().querySelector(".quick-search__results")
const options = () => Array.from(results().querySelectorAll("[role='option']"))

const menuPages = () => {
  const pages = new Map()
  document.querySelectorAll("#accordionSidebar a.collapse-item, #accordionSidebar a.nav-link[href], #accordionSidebar a[data-palette-label]").forEach((link) => {
    const section = link.closest(".collapse-inner")?.dataset.title
    const name = link.dataset.paletteLabel || link.dataset.navLabel || link.textContent.trim()
    if (!pages.has(link.href)) pages.set(link.href, { label: name, detail: section || "", url: link.href })
  })
  return Array.from(pages.values())
}

const select = (option) => {
  options().forEach((el) => el.setAttribute("aria-selected", el === option ? "true" : "false"))
  option?.scrollIntoView({ block: "nearest" })
}

const addGroup = (title, items) => {
  if (items.length === 0) return
  const heading = document.createElement("p")
  heading.className = "quick-search__group"
  heading.textContent = title
  results().append(heading)

  items.forEach((item) => {
    const option = document.createElement("a")
    option.href = item.url
    option.setAttribute("role", "option")
    option.className = "quick-search__option"

    const label = document.createElement("span")
    label.textContent = item.label
    option.append(label)

    if (item.detail) {
      const detail = document.createElement("small")
      detail.textContent = item.detail
      option.append(detail)
    }
    results().append(option)
  })
}

const showMessage = (text) => {
  const message = document.createElement("p")
  message.className = "quick-search__message"
  message.textContent = text
  results().append(message)
}

const render = (term, pages, records, failed) => {
  results().replaceChildren()
  addGroup("Pages", pages)
  addGroup("Clients", records.clients || [])
  addGroup("Invoices", records.invoices || [])
  if (failed) showMessage("Client and invoice search is unavailable. Check your connection and try again.")
  else if (options().length === 0) showMessage(`Nothing matches “${term}”. Try a client name, account number or invoice number.`)
  select(options()[0])
}

const search = () => {
  const term = input().value.trim()
  const needle = term.toLowerCase()
  const pages = menuPages().filter((page) => `${page.label} ${page.detail}`.toLowerCase().includes(needle)).slice(0, needle ? 6 : 8)

  request?.abort()
  render(term, pages, {}, false)
  if (term.length < MINIMUM_SERVER_TERM) return

  request = new AbortController()
  const url = `${dialog().dataset.url}?q=${encodeURIComponent(term)}`
  fetch(url, { headers: { Accept: "application/json" }, signal: request.signal })
    .then((response) => {
      if (!response.ok) throw new Error(`status ${response.status}`)
      return response.json()
    })
    .then((records) => render(term, pages, records, false))
    .catch((error) => { if (error.name !== "AbortError") render(term, pages, {}, true) })
}

const open = () => {
  if (!dialog() || dialog().open) return
  dialog().showModal()
  input().value = ""
  search()
  input().focus()
}

const go = (option) => {
  if (!option) return
  dialog().close()
  window.Turbo.visit(option.href)
}

document.addEventListener("keydown", (event) => {
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k") {
    event.preventDefault()
    open()
    return
  }
  if (!dialog()?.open) return

  const all = options()
  const index = all.findIndex((el) => el.getAttribute("aria-selected") === "true")
  if (event.key === "ArrowDown" || event.key === "ArrowUp") {
    event.preventDefault()
    if (all.length) select(all[(index + (event.key === "ArrowDown" ? 1 : -1) + all.length) % all.length])
  } else if (event.key === "Enter") {
    event.preventDefault()
    go(all[index])
  }
})

document.addEventListener("input", (event) => {
  if (event.target.closest("#quickSearch")) {
    clearTimeout(timer)
    timer = setTimeout(search, SEARCH_DELAY_MS)
  }
})

document.addEventListener("click", (event) => {
  if (event.target.closest("[data-quick-search-open]")) {
    open()
    return
  }
  const box = dialog()
  if (!box?.open) return

  // A click on the backdrop lands on the dialog element itself.
  if (event.target === box) box.close()
  const option = event.target.closest(".quick-search__option")
  if (option) {
    event.preventDefault()
    go(option)
  }
})

document.addEventListener("mousemove", (event) => {
  const option = event.target.closest?.(".quick-search__option")
  if (option && option.getAttribute("aria-selected") !== "true") select(option)
})

// Never let Turbo cache the page with the search box open.
document.addEventListener("turbo:before-cache", () => { if (dialog()?.open) dialog().close() })
