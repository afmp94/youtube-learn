import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "form"]

  reset(event) {
    if (event.detail.success) {
      this.selectTarget.value = ""
    }
  }
}
