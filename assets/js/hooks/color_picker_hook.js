const PRESETS = [
  "#ef4444", "#f97316", "#f59e0b",
  "#22c55e", "#14b8a6", "#3b82f6",
  "#6366f1", "#a855f7", "#ec4899",
  "#64748b"
]

const ColorPickerHook = {
  mounted() {
    this.text = this.el.querySelector("input[type=text]")
    this.swatch = this.el.querySelector("[data-swatch]")
    this.panel = this.el.querySelector("[data-panel]")
    this.nativePicker = this.panel.querySelector("input[type=color]")
    this.okBtn = this.panel.querySelector("[data-ok]")
    this.cancelBtn = this.panel.querySelector("[data-cancel]")
    this.originalValue = ""
    this.pendingValue = ""

    this.syncSwatch()

    this.swatch.addEventListener("click", (e) => {
      e.stopPropagation()
      this.open()
    })

    this.panel.querySelectorAll("[data-preset]").forEach(btn => {
      btn.addEventListener("click", () => {
        this.pendingValue = btn.dataset.preset
        this.nativePicker.value = this.pendingValue
        this.highlightPreset()
      })
    })

    this.nativePicker.addEventListener("input", () => {
      this.pendingValue = this.nativePicker.value
      this.highlightPreset()
    })

    this.okBtn.addEventListener("click", () => this.confirm())
    this.cancelBtn.addEventListener("click", () => this.cancel())

    this.text.addEventListener("input", () => this.syncSwatch())

    this._onClickOutside = (e) => {
      if (!this.el.contains(e.target)) this.cancel()
    }

    this._onKeydown = (e) => {
      if (e.key === "Escape") this.cancel()
      if (e.key === "Enter") { e.preventDefault(); this.confirm() }
    }
  },

  updated() {
    this.syncSwatch()
  },

  open() {
    this.originalValue = this.text.value
    this.pendingValue = this.isHex(this.text.value) ? this.text.value : "#3b82f6"
    this.nativePicker.value = this.pendingValue
    this.highlightPreset()
    this.panel.classList.remove("hidden")
    document.addEventListener("click", this._onClickOutside, true)
    document.addEventListener("keydown", this._onKeydown)
  },

  close() {
    this.panel.classList.add("hidden")
    document.removeEventListener("click", this._onClickOutside, true)
    document.removeEventListener("keydown", this._onKeydown)
  },

  confirm() {
    this.text.value = this.pendingValue
    this.text.dispatchEvent(new Event("input", { bubbles: true }))
    this.syncSwatch()
    this.close()
  },

  cancel() {
    this.text.value = this.originalValue
    this.text.dispatchEvent(new Event("input", { bubbles: true }))
    this.syncSwatch()
    this.close()
  },

  highlightPreset() {
    this.panel.querySelectorAll("[data-preset]").forEach(btn => {
      const ring = btn.dataset.preset.toLowerCase() === this.pendingValue.toLowerCase()
      btn.style.outline = ring ? "2px solid currentColor" : "none"
      btn.style.outlineOffset = ring ? "2px" : "0"
    })
  },

  syncSwatch() {
    if (this.isHex(this.text.value)) {
      this.swatch.style.backgroundColor = this.text.value
    } else {
      this.swatch.style.backgroundColor = "transparent"
    }
  },

  isHex(v) {
    return /^#[0-9a-fA-F]{6}$/.test(v)
  },

  destroyed() {
    document.removeEventListener("click", this._onClickOutside, true)
    document.removeEventListener("keydown", this._onKeydown)
  }
}

export { PRESETS }
export default ColorPickerHook
