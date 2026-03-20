import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeField", "sourceUrlField", "fileField", "bodyField", "bodyLabel"]

  connect() {
    this.updateFields()
  }

  selectType(event) {
    const type = event.currentTarget.dataset.entryType
    this.typeFieldTarget.value = type

    // Update pills
    this.element.querySelectorAll("[data-entry-type]").forEach(pill => {
      if (pill.dataset.entryType === type) {
        pill.classList.add("bg-white", "shadow-sm", "text-indigo-700")
        pill.classList.remove("text-gray-500", "hover:text-gray-700")
      } else {
        pill.classList.remove("bg-white", "shadow-sm", "text-indigo-700")
        pill.classList.add("text-gray-500", "hover:text-gray-700")
      }
    })

    this.updateFields()
  }

  updateFields() {
    const type = this.typeFieldTarget.value

    // Show/hide source URL field
    if (this.hasSourceUrlFieldTarget) {
      this.sourceUrlFieldTarget.classList.toggle("hidden", type !== "link")
    }

    // Show/hide file upload field
    if (this.hasFileFieldTarget) {
      this.fileFieldTarget.classList.toggle("hidden", type !== "file_upload")
    }

    // Update body textarea rows and label
    if (this.hasBodyFieldTarget) {
      const rows = { article: 10, note: 4, link: 3, file_upload: 3, idea: 3 }
      this.bodyFieldTarget.rows = rows[type] || 4
    }

    if (this.hasBodyLabelTarget) {
      const labels = { link: "Notes about this link", file_upload: "Notes about this file" }
      this.bodyLabelTarget.textContent = labels[type] || "Body"
    }
  }
}
