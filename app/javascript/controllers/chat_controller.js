import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "form", "sendButton"]

  connect() {
    this.scrollToBottom()

    // Listen for Turbo Stream events to auto-scroll when new messages arrive
    this.boundHandleStreamRender = this.handleStreamRender.bind(this)
    document.addEventListener("turbo:before-stream-render", this.boundHandleStreamRender)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.boundHandleStreamRender)
  }

  handleStreamRender() {
    // After the stream renders, scroll to bottom
    requestAnimationFrame(() => {
      this.scrollToBottom()
    })
  }

  submit(event) {
    // Don't prevent default - let Turbo handle the form submission
    if (!this.hasInputTarget) return

    const message = this.inputTarget.value.trim()
    if (message === "") {
      event.preventDefault()
      return
    }

    // Clear and reset the input after a brief delay (after form data is captured)
    setTimeout(() => {
      if (this.hasInputTarget) {
        this.inputTarget.value = ""
        this.inputTarget.style.height = "auto"
      }
    }, 50)

    // Disable send button briefly to prevent double-submit
    if (this.hasSendButtonTarget) {
      this.sendButtonTarget.disabled = true
      setTimeout(() => {
        if (this.hasSendButtonTarget) {
          this.sendButtonTarget.disabled = false
        }
      }, 1500)
    }

    // Scroll to bottom after message appears
    setTimeout(() => {
      this.scrollToBottom()
    }, 200)
  }

  keydown(event) {
    // Enter submits (without Shift), Shift+Enter adds newline
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()

      if (this.hasFormTarget) {
        this.formTarget.requestSubmit()
      }
    }
  }

  autoResize(event) {
    const textarea = event.target
    textarea.style.height = "auto"
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + "px"
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    } else {
      // Fallback: try to find the messages container by ID
      const container = document.getElementById("messages_container")
      if (container) {
        container.scrollTop = container.scrollHeight
      }
    }
  }
}
