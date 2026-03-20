import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  fill(event) {
    const text = event.currentTarget.dataset.text
    const textarea = document.querySelector("[data-smart-content-target='prompt']")
    if (textarea) {
      textarea.value = text
      textarea.focus()
      // Trigger input event so smart-content controller updates
      textarea.dispatchEvent(new Event("input", { bubbles: true }))
    }
  }
}
