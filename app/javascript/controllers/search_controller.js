import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  perform() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.inputTarget.form.requestSubmit()
    }, 300)
  }
}
