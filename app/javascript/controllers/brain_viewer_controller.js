import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "image", "bar"]

  connect() {
    this.animateBars()
  }

  selectView(event) {
    const view = event.currentTarget.dataset.view

    // Update tab styles
    this.tabTargets.forEach(tab => {
      if (tab.dataset.view === view) {
        tab.style.background = "#1e1e2e"
        tab.style.color = "#e2e2ef"
      } else {
        tab.style.background = "transparent"
        tab.style.color = "#6b6b80"
      }
    })

    // Show/hide images
    this.imageTargets.forEach(img => {
      if (img.dataset.view === view) {
        img.classList.remove("hidden")
      } else {
        img.classList.add("hidden")
      }
    })
  }

  animateBars() {
    requestAnimationFrame(() => {
      this.barTargets.forEach((bar, index) => {
        const score = parseInt(bar.dataset.score) || 0
        setTimeout(() => {
          bar.style.width = `${score}%`
        }, 300 + index * 100)
      })
    })
  }
}
