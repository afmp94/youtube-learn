import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  update(event) {
    const status = event.currentTarget.dataset.status
    const url = this.urlValue
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html, text/html"
      },
      body: JSON.stringify({ status: status })
    }).then(response => {
      if (response.ok) {
        return response.text()
      }
      throw new Error("Status update failed")
    }).then(html => {
      // If Turbo Stream response, it will be auto-processed
      // Otherwise reload the page to show the updated status
      if (!html.includes("turbo-stream")) {
        window.location.reload()
      } else {
        // Process turbo stream manually
        Turbo.renderStreamMessage(html)
        // Also hide the clicked button and show the previous status button
        this.element.querySelectorAll("button[data-status]").forEach(btn => {
          btn.classList.remove("hidden")
        })
        event.currentTarget.classList.add("hidden")
      }
    }).catch(() => {
      window.location.reload()
    })
  }
}
