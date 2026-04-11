import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "inputType"]

  connect() {
    this.selectTab("free_text")
  }

  select(event) {
    const tabName = event.currentTarget.dataset.tab
    this.selectTab(tabName)
  }

  selectTab(tabName) {
    this.tabTargets.forEach(tab => {
      if (tab.dataset.tab === tabName) {
        tab.classList.add("bg-white", "shadow-sm", "text-indigo-700")
        tab.classList.remove("text-gray-500")
      } else {
        tab.classList.remove("bg-white", "shadow-sm", "text-indigo-700")
        tab.classList.add("text-gray-500")
      }
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.tab !== tabName)
    })

    // Update hidden input_type fields in all forms within the active panel
    if (this.hasInputTypeTarget) {
      this.inputTypeTarget.value = tabName
    }
  }
}
