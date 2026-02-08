const CameraHook = {
  mounted() {
    this.video = null
    this.stream = null
    this.canvas = document.createElement("canvas")

    this.el.addEventListener("click", () => this.openCamera())
  },

  async openCamera() {
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment" }
      })

      const modal = document.createElement("div")
      modal.className = "fixed inset-0 z-50 flex items-center justify-center bg-black/70"
      modal.innerHTML = `
        <div class="bg-base-100 rounded-lg p-4 max-w-lg w-full mx-4">
          <video autoplay playsinline class="w-full rounded-lg"></video>
          <div class="flex gap-2 mt-3 justify-center">
            <button type="button" class="btn btn-primary" data-action="capture">
              Take Photo
            </button>
            <button type="button" class="btn btn-ghost" data-action="cancel">
              Cancel
            </button>
          </div>
        </div>
      `

      document.body.appendChild(modal)
      this.video = modal.querySelector("video")
      this.video.srcObject = this.stream

      modal.querySelector("[data-action=capture]").addEventListener("click", () => {
        this.capture()
        this.closeCamera(modal)
      })

      modal.querySelector("[data-action=cancel]").addEventListener("click", () => {
        this.closeCamera(modal)
      })

      modal.addEventListener("click", (e) => {
        if (e.target === modal) this.closeCamera(modal)
      })
    } catch (err) {
      console.error("Camera error:", err)
      alert("Could not access camera. Please check permissions.")
    }
  },

  capture() {
    this.canvas.width = this.video.videoWidth
    this.canvas.height = this.video.videoHeight
    this.canvas.getContext("2d").drawImage(this.video, 0, 0)

    this.canvas.toBlob((blob) => {
      const name = `camera_${Date.now()}.jpg`
      const file = new File([blob], name, { type: "image/jpeg" })

      // Find the live_file_input by looking for the input inside the same form
      const form = this.el.closest("form") || this.el.closest("[phx-target]")
      const input = form && form.querySelector("input[type=file]")
      if (input) {
        const dt = new DataTransfer()
        dt.items.add(file)
        input.files = dt.files
        input.dispatchEvent(new Event("change", { bubbles: true }))
      }
    }, "image/jpeg", 0.9)
  },

  closeCamera(modal) {
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop())
      this.stream = null
    }
    if (this.video) {
      this.video.srcObject = null
      this.video = null
    }
    modal.remove()
  },

  destroyed() {
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop())
    }
  }
}

export default CameraHook
