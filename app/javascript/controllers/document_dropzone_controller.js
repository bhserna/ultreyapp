import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status"]

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "copy"
    this.element.classList.add("documents__dropzone--active")
  }

  dragLeave(event) {
    if (!this.element.contains(event.relatedTarget)) {
      this.element.classList.remove("documents__dropzone--active")
    }
  }

  drop(event) {
    event.preventDefault()
    this.element.classList.remove("documents__dropzone--active")

    if (event.dataTransfer.files.length === 0) return

    this.inputTarget.files = event.dataTransfer.files
    this.upload()
  }

  upload() {
    if (this.uploading || this.inputTarget.files.length === 0) return

    this.uploading = true
    this.statusTarget.textContent = "Subiendo documentos…"
    this.element.requestSubmit()
  }

  submitEnd(event) {
    if (event.detail.success) return

    this.uploading = false
    this.statusTarget.textContent = "No se pudieron subir los documentos. Inténtalo de nuevo."
  }
}
