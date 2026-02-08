import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

import CameraHook from "./hooks/camera_hook"
import CodeScannerHook from "./hooks/code_scanner_hook"
import ColorPickerHook from "./hooks/color_picker_hook"
import ScannerHook from "./hooks/scanner_hook"
import ThemeHook from "./hooks/theme_hook"

let Hooks = {
  CameraHook,
  CodeScannerHook,
  ColorPickerHook,
  ScannerHook,
  ThemeHook
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) { window.Alpine.clone(from, to) }
    }
  }
})

// Handle data-confirm on phx-click elements
document.addEventListener("click", (e) => {
  let el = e.target.closest("[data-confirm]")
  if (el && !confirm(el.dataset.confirm)) {
    e.preventDefault()
    e.stopPropagation()
  }
}, true)

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
