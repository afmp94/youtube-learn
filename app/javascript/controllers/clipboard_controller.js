import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  copy(event) {
    const content = event.currentTarget.dataset.content
    navigator.clipboard.writeText(content).then(() => {
      const button = event.currentTarget
      const originalText = button.innerHTML
      button.innerHTML = `<svg class="w-3.5 h-3.5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg> Copied!`
      setTimeout(() => { button.innerHTML = originalText }, 2000)
    })
  }
}
