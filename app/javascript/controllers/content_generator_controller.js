import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "platformField", "formatField", "templateField", "collectionField",
    "platformCards", "formatSection", "formatCards", "sourceSection",
    "templateSection", "templateCards", "generateButton",
    "videoCheckboxes", "videoCheckbox", "collectionSelectWrapper", "collectionSelect",
    "videosToggle", "collectionToggle", "selectAllBtn"
  ]

  static values = {
    selectedPlatform: String,
    selectedFormat: String,
    selectedTemplate: String
  }

  // Platform to available formats mapping
  platformFormats = {
    linkedin: ["post", "carousel_outline", "hooks_list"],
    twitter: ["thread", "post", "hooks_list"],
    youtube_script: ["script"],
    blog: ["article"],
    newsletter: ["article", "post"]
  }

  connect() {
    this.sourceType = "videos"
    this.updateGenerateButton()
  }

  selectPlatform(event) {
    const platform = event.currentTarget.dataset.platform
    this.selectedPlatformValue = platform
    this.platformFieldTarget.value = platform

    // Reset format and template
    this.selectedFormatValue = ""
    this.formatFieldTarget.value = ""
    this.selectedTemplateValue = ""
    this.templateFieldTarget.value = ""

    // Highlight selected platform card
    this.platformCardsTarget.querySelectorAll(".platform-card").forEach(card => {
      const selected = card.querySelector(".platform-selected")
      if (card.dataset.platform === platform) {
        card.classList.add("border-transparent")
        card.classList.remove("border-gray-200")
        selected.style.opacity = "1"
      } else {
        card.classList.remove("border-transparent")
        card.classList.add("border-gray-200")
        selected.style.opacity = "0"
      }
    })

    // Show format section and filter format cards
    this.formatSectionTarget.classList.remove("hidden")
    const availableFormats = this.platformFormats[platform] || []
    this.formatCardsTarget.querySelectorAll(".format-card").forEach(card => {
      const cardPlatforms = (card.dataset.platforms || "").split(",")
      if (cardPlatforms.includes(platform)) {
        card.classList.remove("hidden")
      } else {
        card.classList.add("hidden")
      }
      // Reset format selection
      const selected = card.querySelector(".format-selected")
      selected.style.opacity = "0"
      card.classList.remove("border-transparent")
      card.classList.add("border-gray-200")
    })

    // Auto-select if only one format available
    if (availableFormats.length === 1) {
      const singleCard = this.formatCardsTarget.querySelector(`[data-format="${availableFormats[0]}"]`)
      if (singleCard) {
        singleCard.click()
      }
    }

    // Show source section
    this.sourceSectionTarget.classList.remove("hidden")

    // Hide template section until format is selected
    this.templateSectionTarget.classList.add("hidden")

    this.updateGenerateButton()
  }

  selectFormat(event) {
    const format = event.currentTarget.dataset.format
    this.selectedFormatValue = format
    this.formatFieldTarget.value = format

    // Reset template
    this.selectedTemplateValue = ""
    this.templateFieldTarget.value = ""

    // Highlight selected format card
    this.formatCardsTarget.querySelectorAll(".format-card").forEach(card => {
      const selected = card.querySelector(".format-selected")
      if (card.dataset.format === format) {
        card.classList.add("border-transparent")
        card.classList.remove("border-gray-200")
        selected.style.opacity = "1"
      } else {
        card.classList.remove("border-transparent")
        card.classList.add("border-gray-200")
        selected.style.opacity = "0"
      }
    })

    // Show template section and filter templates
    this.templateSectionTarget.classList.remove("hidden")
    const platform = this.selectedPlatformValue
    this.templateCardsTarget.querySelectorAll(".template-card").forEach(card => {
      const cardPlatforms = card.dataset.platforms
      if (!cardPlatforms) {
        // The "Auto-generate" card has no platforms, always show it
        card.classList.remove("hidden")
      } else if (cardPlatforms.split(",").includes(platform)) {
        card.classList.remove("hidden")
      } else {
        card.classList.add("hidden")
      }
      // Reset template selection except auto-generate
      const selected = card.querySelector(".template-selected")
      if (!cardPlatforms) {
        // Auto-generate stays selected by default
        selected.style.opacity = "1"
        card.classList.add("border-indigo-300")
        card.classList.remove("border-gray-200")
      } else {
        selected.style.opacity = "0"
        card.classList.remove("border-transparent")
        card.classList.add("border-gray-200")
      }
    })

    this.updateGenerateButton()
  }

  selectTemplate(event) {
    const template = event.currentTarget.dataset.template
    this.selectedTemplateValue = template
    this.templateFieldTarget.value = template

    // Highlight selected template card
    this.templateCardsTarget.querySelectorAll(".template-card").forEach(card => {
      const selected = card.querySelector(".template-selected")
      if (card.dataset.template === template) {
        card.classList.add("border-indigo-300")
        card.classList.remove("border-gray-200")
        selected.style.opacity = "1"
      } else {
        card.classList.remove("border-indigo-300")
        card.classList.add("border-gray-200")
        selected.style.opacity = "0"
      }
    })
  }

  toggleSource(event) {
    const sourceType = event.currentTarget.dataset.sourceType
    this.sourceType = sourceType

    if (sourceType === "collection") {
      this.videoCheckboxesTarget.classList.add("hidden")
      if (this.hasCollectionSelectWrapperTarget) {
        this.collectionSelectWrapperTarget.classList.remove("hidden")
      }
      // Update toggle button styles
      if (this.hasCollectionToggleTarget) {
        this.collectionToggleTarget.classList.add("bg-indigo-100", "text-indigo-700", "border-indigo-200")
        this.collectionToggleTarget.classList.remove("bg-gray-100", "text-gray-600", "border-gray-200")
      }
      if (this.hasVideosToggleTarget) {
        this.videosToggleTarget.classList.remove("bg-indigo-100", "text-indigo-700", "border-indigo-200")
        this.videosToggleTarget.classList.add("bg-gray-100", "text-gray-600", "border-gray-200")
      }
      // Uncheck all individual videos
      this.videoCheckboxTargets.forEach(cb => cb.checked = false)
    } else {
      this.videoCheckboxesTarget.classList.remove("hidden")
      if (this.hasCollectionSelectWrapperTarget) {
        this.collectionSelectWrapperTarget.classList.add("hidden")
      }
      // Update toggle button styles
      if (this.hasVideosToggleTarget) {
        this.videosToggleTarget.classList.add("bg-indigo-100", "text-indigo-700", "border-indigo-200")
        this.videosToggleTarget.classList.remove("bg-gray-100", "text-gray-600", "border-gray-200")
      }
      if (this.hasCollectionToggleTarget) {
        this.collectionToggleTarget.classList.remove("bg-indigo-100", "text-indigo-700", "border-indigo-200")
        this.collectionToggleTarget.classList.add("bg-gray-100", "text-gray-600", "border-gray-200")
      }
      // Clear collection selection
      if (this.hasCollectionSelectTarget) {
        this.collectionSelectTarget.value = ""
      }
      this.collectionFieldTarget.value = ""
    }

    this.updateGenerateButton()
  }

  selectCollection(event) {
    this.collectionFieldTarget.value = event.currentTarget.value
    this.updateGenerateButton()
  }

  toggleAllVideos() {
    const allChecked = this.videoCheckboxTargets.every(cb => cb.checked)
    this.videoCheckboxTargets.forEach(cb => cb.checked = !allChecked)

    if (this.hasSelectAllBtnTarget) {
      this.selectAllBtnTarget.textContent = allChecked ? "Select all" : "Deselect all"
    }

    this.updateGenerateButton()
  }

  updateGenerateButton() {
    const hasPlatform = this.selectedPlatformValue !== ""
    const hasFormat = this.selectedFormatValue !== ""
    let hasSource = false

    if (this.sourceType === "collection") {
      hasSource = this.hasCollectionSelectTarget && this.collectionSelectTarget.value !== ""
    } else {
      hasSource = this.videoCheckboxTargets.some(cb => cb.checked)
    }

    const canGenerate = hasPlatform && hasFormat && hasSource

    if (this.hasGenerateButtonTarget) {
      this.generateButtonTarget.disabled = !canGenerate
    }
  }
}
