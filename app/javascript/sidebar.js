import { Collapse } from "bootstrap"

const STORAGE_KEY = "sidebar-collapsed"
const TOGGLE_BUTTONS = "#sidebarToggle, #sidebarToggleTop"
const SECTION_BUTTON = "button.nav-link[data-bs-toggle='collapse']"
const DRAWER_WIDTH = 768
const FLYOUT_MARGIN = 8

const isDrawer = () => window.innerWidth < DRAWER_WIDTH

const readPreference = () => {
  try { return localStorage.getItem(STORAGE_KEY) === "1" } catch { return false }
}

const savePreference = (collapsed) => {
  try { localStorage.setItem(STORAGE_KEY, collapsed ? "1" : "0") } catch { /* private browsing */ }
}

const shouldStartCollapsed = () => isDrawer() || readPreference()

const setCollapsed = (body, collapsed) => {
  body.classList.toggle("sidebar-toggled", collapsed)
  body.querySelector("#accordionSidebar")?.classList.toggle("toggled", collapsed)
}

const isIconRail = () => !isDrawer() && document.body.classList.contains("sidebar-toggled")

// The link for the current page: an exact match, otherwise its parent section,
// so /clients/12 highlights "View clients".
const findCurrentLink = (sidebar) => {
  const path = window.location.pathname.replace(/\/$/, "") || "/"
  let best = null
  let bestLength = 0

  sidebar.querySelectorAll("a.collapse-item[href], a.nav-link[href]").forEach((link) => {
    const linkPath = new URL(link.href).pathname.replace(/\/$/, "") || "/"
    const matches = path === linkPath || (linkPath !== "/" && path.startsWith(`${linkPath}/`))
    if (matches && linkPath.length > bestLength) {
      best = link
      bestLength = linkPath.length
    }
  })
  return best
}

const showCurrentPage = (body) => {
  const sidebar = body.querySelector("#accordionSidebar")
  if (!sidebar) return

  const current = findCurrentLink(sidebar)
  const section = current?.closest(".collapse")
  const keepOpen = Boolean(section) && !sidebar.classList.contains("toggled")

  sidebar.querySelectorAll(".nav-item.active, .collapse-item.active").forEach((el) => el.classList.remove("active"))
  sidebar.querySelectorAll("[aria-current]").forEach((el) => el.removeAttribute("aria-current"))
  sidebar.querySelectorAll(SECTION_BUTTON).forEach((button) => {
    const open = keepOpen && button.dataset.bsTarget === `#${section.id}`
    button.classList.toggle("collapsed", !open)
    button.setAttribute("aria-expanded", open ? "true" : "false")
  })
  sidebar.querySelectorAll(".collapse").forEach((el) => el.classList.toggle("show", keepOpen && el === section))

  if (current) {
    current.setAttribute("aria-current", "page")
    current.closest(".nav-item")?.classList.add("active")
    if (current.classList.contains("collapse-item")) current.classList.add("active")
  }
}

const closeSections = () => {
  document.querySelectorAll("#accordionSidebar .collapse.show").forEach((el) => {
    Collapse.getOrCreateInstance(el, { toggle: false }).hide()
  })
}

const prepare = (body) => {
  setCollapsed(body, shouldStartCollapsed())
  showCurrentPage(body)
}

// One shared tooltip for the icon rail. It sits on the body so the menu's
// scrolling area cannot clip it.
const tooltip = () => {
  let tip = document.getElementById("navTooltip")
  if (!tip) {
    tip = document.createElement("div")
    tip.id = "navTooltip"
    tip.className = "app-nav-tip"
    tip.setAttribute("role", "tooltip")
    document.body.append(tip)
  }
  return tip
}

const hideTooltip = () => document.getElementById("navTooltip")?.classList.remove("visible")

const showTooltip = (target) => {
  const expanded = target.getAttribute("aria-expanded") === "true"
  const label = target.dataset.navLabel
  if (!isIconRail() || expanded || !label) return hideTooltip()

  const box = target.getBoundingClientRect()
  const tip = tooltip()
  tip.textContent = label
  tip.style.top = `${box.top + box.height / 2}px`
  tip.style.left = `${box.right + FLYOUT_MARGIN}px`
  tip.classList.add("visible")
}

const tooltipTarget = (event) => event.target.closest?.("#accordionSidebar [data-nav-label]")

document.addEventListener("mouseover", (event) => {
  const target = tooltipTarget(event)
  if (target) showTooltip(target)
  else hideTooltip()
})
document.addEventListener("focusin", (event) => {
  const target = tooltipTarget(event)
  if (target) showTooltip(target)
})
document.addEventListener("focusout", hideTooltip)

// In the icon rail a section opens beside its icon.
document.addEventListener("show.bs.collapse", (event) => {
  if (!event.target.closest("#accordionSidebar")) return
  hideTooltip()
  if (!isIconRail()) {
    event.target.style.top = ""
    return
  }
  const button = document.querySelector(`[data-bs-target="#${event.target.id}"]`)
  event.target.style.top = `${button.getBoundingClientRect().top}px`
})

document.addEventListener("shown.bs.collapse", (event) => {
  if (!isIconRail() || !event.target.closest("#accordionSidebar")) return
  const box = event.target.getBoundingClientRect()
  const overflow = box.bottom + FLYOUT_MARGIN - window.innerHeight
  if (overflow > 0) event.target.style.top = `${Math.max(FLYOUT_MARGIN, box.top - overflow)}px`
})

// Listeners sit on the document because Turbo replaces the page body.
document.addEventListener("click", (event) => {
  if (event.target.closest(TOGGLE_BUTTONS)) {
    const collapsed = !document.body.classList.contains("sidebar-toggled")
    setCollapsed(document.body, collapsed)
    if (!isDrawer()) savePreference(collapsed)
    hideTooltip()
    if (collapsed) closeSections()
    else showCurrentPage(document.body)
    return
  }

  if (!event.target.closest("#accordionSidebar")) {
    if (isIconRail()) closeSections()
    if (isDrawer() && !document.body.classList.contains("sidebar-toggled")) setCollapsed(document.body, true)
  }

  if (event.target.closest("a.scroll-to-top")) {
    event.preventDefault()
    window.scrollTo({ top: 0, behavior: "smooth" })
  }
})

document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape") return
  if (isIconRail()) closeSections()
  if (isDrawer()) setCollapsed(document.body, true)
})

document.addEventListener("scroll", () => {
  const button = document.querySelector(".scroll-to-top")
  if (button) button.style.display = window.scrollY > 100 ? "block" : "none"
}, { passive: true })

let wasDrawer = isDrawer()
window.addEventListener("resize", () => {
  if (wasDrawer === isDrawer()) return
  wasDrawer = isDrawer()
  prepare(document.body)
})

// On a phone, leaving the page (a link, or the Back button) closes the drawer.
const closeDrawer = () => { if (isDrawer()) setCollapsed(document.body, true) }
document.addEventListener("turbo:visit", closeDrawer)
window.addEventListener("popstate", closeDrawer)
document.addEventListener("turbo:before-cache", closeDrawer)

document.addEventListener("turbo:before-render", (event) => prepare(event.detail.newBody))
document.addEventListener("turbo:load", () => prepare(document.body))
