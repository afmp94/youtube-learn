import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label"]
  static values = { body: String }

  copy() {
    const text = this.bodyValue

    navigator.clipboard.writeText(text).then(() => {
      if (this.hasLabelTarget) {
        const originalText = this.labelTarget.textContent
        this.labelTarget.textContent = "Copied!"
        setTimeout(() => {
          this.labelTarget.textContent = originalText
        }, 2000)
      }
    }).catch(() => {
      // Fallback for older browsers
      const textarea = document.createElement("textarea")
      textarea.value = text
      textarea.style.position = "fixed"
      textarea.style.opacity = "0"
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand("copy")
      document.body.removeChild(textarea)

      if (this.hasLabelTarget) {
        const originalText = this.labelTarget.textContent
        this.labelTarget.textContent = "Copied!"
        setTimeout(() => {
          this.labelTarget.textContent = originalText
        }, 2000)
      }
    })
  }
}
