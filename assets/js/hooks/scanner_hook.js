// Scanner hook - integrates camera-based barcode/QR scanning
// Uses the html5-qrcode library when available
const ScannerHook = {
  mounted() {
    this.scanning = false
    this.scanner = null

    this.el.querySelector("[data-scan-start]")?.addEventListener("click", () => {
      this.startScanning()
    })

    this.el.querySelector("[data-scan-stop]")?.addEventListener("click", () => {
      this.stopScanning()
    })
  },

  async startScanning() {
    const readerEl = this.el.querySelector("[data-scanner-reader]")
    if (!readerEl) return

    // Check if Html5QrcodeScanner is available
    if (typeof Html5Qrcode === "undefined") {
      // Fallback: prompt for manual input
      const value = prompt("Enter barcode/QR value manually:")
      if (value) {
        this.pushEvent("scanned", { value: value })
      }
      return
    }

    try {
      this.scanner = new Html5Qrcode(readerEl.id)
      this.scanning = true

      await this.scanner.start(
        { facingMode: "environment" },
        { fps: 10, qrbox: 250 },
        (decodedText) => {
          this.pushEvent("scanned", { value: decodedText })
          this.stopScanning()
        },
        () => {} // ignore errors during scanning
      )
    } catch (err) {
      console.error("Scanner error:", err)
      const value = prompt("Camera not available. Enter value manually:")
      if (value) {
        this.pushEvent("scanned", { value: value })
      }
    }
  },

  async stopScanning() {
    if (this.scanner && this.scanning) {
      try {
        await this.scanner.stop()
      } catch (e) {
        // ignore
      }
      this.scanning = false
    }
  },

  destroyed() {
    this.stopScanning()
  }
}

export default ScannerHook
