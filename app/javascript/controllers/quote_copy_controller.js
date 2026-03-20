import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text"]

  copy(event) {
    const text = this.textTarget.innerText || this.textTarget.textContent
    navigator.clipboard.writeText(text).then(() => {
      const button = event.currentTarget
      const originalHTML = button.innerHTML
      button.innerHTML = `<svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg> Copied!`
      button.classList.remove("text-gray-500", "hover:text-indigo-600")
      button.classList.add("text-green-600")
      setTimeout(() => {
        button.innerHTML = originalHTML
        button.classList.remove("text-green-600")
        button.classList.add("text-gray-500", "hover:text-indigo-600")
      }, 2000)
    })
  }
}
