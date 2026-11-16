// Live search for every list page: results update while you type, like Generate License.
// Works on any GET filter form (form.zfilters) with a search box. The page is fetched in the
// background and everything around the search box is swapped in, so the cursor never leaves it.
const DELAY = 300
const MINIMUM = 2
let timer = null
let pending = null

const searchBox = (el) =>
  el instanceof HTMLInputElement && el.type === "search" && el.form &&
  el.form.matches("form.zfilters") && (el.form.method || "get").toLowerCase() === "get" &&
  !el.form.matches("[data-controller~='autosubmit']") && el.closest(".zpage")

function urlFor(form) {
  const url = new URL(form.action || window.location.href, window.location.href)
  const params = new URLSearchParams()
  for (const [key, value] of new FormData(form)) {
    if (key === "page" || key === "utf8" || value === "") continue
    params.append(key, value)
  }
  url.search = params.toString()
  return url
}

// Replace every node except the chain of parents that holds the search box itself.
function swapAround(oldParent, newParent, oldInput, newInput) {
  if (oldParent === oldInput) return true
  const oldKeep = [...oldParent.children].find((c) => c.contains(oldInput))
  const newKeep = [...newParent.children].find((c) => c.contains(newInput))
  if (!oldKeep || !newKeep) return false
  ;[...oldParent.childNodes].forEach((n) => { if (n !== oldKeep) n.remove() })
  let before = true
  ;[...newParent.childNodes].forEach((n) => {
    if (n === newKeep) { before = false; return }
    const copy = document.importNode(n, true)
    before ? oldParent.insertBefore(copy, oldKeep) : oldParent.appendChild(copy)
  })
  if (oldKeep !== oldInput) {
    // Keep the box's own attributes (classes may change, e.g. "on") without touching the input.
    for (const { name, value } of [...newKeep.attributes]) oldKeep.setAttribute(name, value)
  }
  return swapAround(oldKeep, newKeep, oldInput, newInput)
}

async function refresh(input) {
  const form = input.form
  const url = urlFor(form)
  pending?.abort()
  pending = new AbortController()
  try {
    form.setAttribute("aria-busy", "true")
    const response = await fetch(url, { headers: { Accept: "text/html" }, signal: pending.signal, credentials: "same-origin" })
    if (!response.ok || response.redirected) return
    const doc = new DOMParser().parseFromString(await response.text(), "text/html")
    const newInput = doc.querySelector(`form.zfilters input[type="search"][name="${CSS.escape(input.name)}"]`)
    const oldPage = input.closest(".zpage")
    const newPage = newInput?.closest(".zpage")
    if (!newPage || !swapAround(oldPage, newPage, input, newInput)) {
      window.Turbo ? Turbo.visit(url.toString(), { action: "replace" }) : (window.location.href = url)
      return
    }
    window.history.replaceState(window.history.state, "", url.toString())
    document.dispatchEvent(new CustomEvent("live-search:updated", { detail: { url } }))
  } catch (error) {
    if (error.name !== "AbortError") console.warn("Live search failed", error)
  } finally {
    form.removeAttribute("aria-busy")
  }
}

document.addEventListener("input", (event) => {
  const input = event.target
  if (!searchBox(input)) return
  clearTimeout(timer)
  const length = input.value.trim().length
  if (length > 0 && length < MINIMUM) return
  timer = setTimeout(() => refresh(input), DELAY)
})

// Pressing Enter still works; it just cancels the pending background search.
document.addEventListener("submit", (event) => {
  if (event.target.matches?.("form.zfilters")) { clearTimeout(timer); pending?.abort() }
})
document.addEventListener("turbo:before-visit", () => { clearTimeout(timer); pending?.abort() })
