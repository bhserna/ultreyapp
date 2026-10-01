import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  initialize() {
    this.resizeOnWindow = () => this.resize()
  }

  connect() {
    this.resize()
    window.addEventListener("resize", this.resizeOnWindow)
  }

  disconnect() {
    window.removeEventListener("resize", this.resizeOnWindow)
  }

  resize() {
    this.element.style.height = "auto"
    const borderHeight = this.element.offsetHeight - this.element.clientHeight
    this.element.style.height = `${this.element.scrollHeight + borderHeight}px`
  }
}
