import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]

  connect() {
    this.submitTarget.hidden = true
  }

  submit() {
    this.element.requestSubmit()
  }
}
