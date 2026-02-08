import { BarcodeDetector } from "barcode-detector/pure"

const FORMATS = [
  "qr_code", "ean_13", "ean_8", "code_128", "code_39",
  "upc_a", "upc_e", "data_matrix", "pdf417", "aztec",
  "itf", "codabar"
]

const CodeScannerHook = {
  mounted() {
    this.video = null
    this.canvas = null
    this.stream = null
    this.detector = null
    this.animFrameId = null

    this.el.addEventListener("click", () => this.openScanner())
  },

  async openScanner() {
    try {
      this.detector = new BarcodeDetector({ formats: FORMATS })

      this.stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment" }
      })

      const modal = document.createElement("div")
      modal.className = "fixed inset-0 z-50 flex items-center justify-center bg-black/70"
      modal.innerHTML = `
        <div class="bg-base-100 rounded-lg p-4 max-w-lg w-full mx-4">
          <div class="relative">
            <video autoplay playsinline class="w-full rounded-lg"></video>
            <canvas class="absolute inset-0 w-full h-full rounded-lg pointer-events-none"></canvas>
          </div>
          <p class="text-center text-sm opacity-60 mt-2">Point camera at barcode or QR code</p>
          <div class="flex gap-2 mt-3 justify-center">
            <button type="button" class="btn btn-ghost" data-action="cancel">
              Cancel
            </button>
          </div>
        </div>
      `

      document.body.appendChild(modal)
      this.video = modal.querySelector("video")
      this.canvas = modal.querySelector("canvas")
      this.video.srcObject = this.stream

      this.video.addEventListener("loadeddata", () => {
        this.canvas.width = this.video.videoWidth
        this.canvas.height = this.video.videoHeight
        this.scanLoop(modal)
      })

      modal.querySelector("[data-action=cancel]").addEventListener("click", () => {
        this.closeScanner(modal)
      })

      modal.addEventListener("click", (e) => {
        if (e.target === modal) this.closeScanner(modal)
      })
    } catch (err) {
      console.error("Scanner error:", err)
      alert("Could not access camera. Please check permissions.")
    }
  },

  drawOverlay(barcodes) {
    const ctx = this.canvas.getContext("2d")
    ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)

    for (const barcode of barcodes) {
      const points = barcode.cornerPoints
      if (!points || points.length < 4) continue

      ctx.strokeStyle = "#22c55e"
      ctx.lineWidth = 3
      ctx.beginPath()
      ctx.moveTo(points[0].x, points[0].y)
      for (let i = 1; i < points.length; i++) {
        ctx.lineTo(points[i].x, points[i].y)
      }
      ctx.closePath()
      ctx.stroke()

      // Semi-transparent fill
      ctx.fillStyle = "rgba(34, 197, 94, 0.1)"
      ctx.fill()

      // Label
      const minY = Math.min(...points.map(p => p.y))
      const minX = Math.min(...points.map(p => p.x))
      ctx.font = "14px sans-serif"
      ctx.fillStyle = "#22c55e"
      ctx.fillText(barcode.rawValue, minX, minY - 6)
    }
  },

  async scanLoop(modal) {
    if (!this.video || !this.detector) return

    try {
      const barcodes = await this.detector.detect(this.video)
      this.drawOverlay(barcodes)

      if (barcodes.length > 0) {
        // Brief pause so the user sees the detection overlay
        await new Promise(r => setTimeout(r, 400))
        this.pushEvent("scanned", { value: barcodes[0].rawValue })
        this.closeScanner(modal)
        return
      }
    } catch (err) {
      // ignore detection errors on individual frames
    }

    this.animFrameId = requestAnimationFrame(() => this.scanLoop(modal))
  },

  closeScanner(modal) {
    if (this.animFrameId) {
      cancelAnimationFrame(this.animFrameId)
      this.animFrameId = null
    }
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop())
      this.stream = null
    }
    if (this.video) {
      this.video.srcObject = null
      this.video = null
    }
    this.canvas = null
    this.detector = null
    modal.remove()
  },

  destroyed() {
    if (this.animFrameId) {
      cancelAnimationFrame(this.animFrameId)
    }
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop())
    }
  }
}

export default CodeScannerHook
