import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["prompt", "platformField", "platformGroup", "submitButton", "charCount"]

  connect() {
    this.updateButton()
  }

  selectPlatform(event) {
    const platform = event.currentTarget.dataset.platform

    // Update hidden field
    this.platformFieldTarget.value = platform

    // Update pill styles
    this.platformGroupTarget.querySelectorAll(".platform-pill").forEach(pill => {
      if (pill.dataset.platform === platform) {
        pill.classList.remove("text-gray-500", "hover:text-gray-700")
        pill.classList.add("bg-white", "shadow-sm")

        // Platform-specific text color
        const colors = {
          linkedin: "text-blue-700",
          twitter: "text-sky-700",
          youtube_script: "text-red-700",
          blog: "text-purple-700",
          newsletter: "text-amber-700"
        }
        Object.values(colors).forEach(c => pill.classList.remove(c))
        pill.classList.add(colors[platform] || "text-indigo-700")
      } else {
        pill.classList.add("text-gray-500", "hover:text-gray-700")
        pill.classList.remove("bg-white", "shadow-sm", "text-blue-700", "text-sky-700", "text-red-700", "text-purple-700", "text-amber-700")
      }
    })
  }

  updateButton() {
    const hasText = this.promptTarget.value.trim().length > 10
    this.submitButtonTarget.disabled = !hasText

    // Update char count
    const count = this.promptTarget.value.length
    this.charCountTarget.textContent = `${count} chars`
  }

  submit(event) {
    if (this.promptTarget.value.trim().length <= 10) {
      event.preventDefault()
      return
    }

    // Disable button and show loading state
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.innerHTML = `
      <svg class="animate-spin w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Creating...
    `
  }
}
