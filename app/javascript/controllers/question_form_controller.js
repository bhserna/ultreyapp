import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "panel"]

  show() {
    this.triggerTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.panelTarget.hidden = false
    this.panelTarget.querySelector("textarea")?.focus()
  }

  hide() {
    this.panelTarget.querySelector("form")?.reset()
    this.panelTarget.hidden = true
    this.triggerTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.triggerTarget.focus()
  }
}
