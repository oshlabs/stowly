// Theme hook - applies per-collection theme overrides
// Reads theme data from the element's data attributes and applies
// CSS custom properties and data-theme to the document root
const ThemeHook = {
  mounted() {
    this.applyTheme()
  },

  updated() {
    this.applyTheme()
  },

  destroyed() {
    this.resetTheme()
  },

  applyTheme() {
    const el = this.el
    const baseTheme = el.dataset.baseTheme
    const overrides = el.dataset.themeOverrides

    if (baseTheme) {
      document.documentElement.setAttribute("data-theme", baseTheme)
    }

    if (overrides) {
      try {
        const props = JSON.parse(overrides)
        Object.entries(props).forEach(([key, value]) => {
          if (value) {
            document.documentElement.style.setProperty(key, value)
          }
        })
        this._appliedProps = Object.keys(props)
      } catch (e) {
        console.error("Failed to parse theme overrides:", e)
      }
    }
  },

  resetTheme() {
    // Reset to default light theme
    document.documentElement.setAttribute("data-theme", "light")

    // Remove any custom properties we set
    if (this._appliedProps) {
      this._appliedProps.forEach(key => {
        document.documentElement.style.removeProperty(key)
      })
      this._appliedProps = null
    }
  }
}

export default ThemeHook
