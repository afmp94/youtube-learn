import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "thumbnail", "hint", "submit"]

  validate() {
    const url = this.inputTarget.value.trim()
    const videoId = this.extractVideoId(url)

    if (videoId) {
      this.hintTarget.textContent = "Valid YouTube URL detected"
      this.hintTarget.classList.remove("text-red-500")
      this.hintTarget.classList.add("text-green-600")
      this.showPreview(videoId)
      this.submitTarget.disabled = false
    } else if (url.length > 0) {
      this.hintTarget.textContent = "Please enter a valid YouTube URL"
      this.hintTarget.classList.add("text-red-500")
      this.hintTarget.classList.remove("text-green-600")
      this.hidePreview()
    } else {
      this.hintTarget.textContent = "Paste a YouTube video URL to analyze"
      this.hintTarget.classList.remove("text-red-500", "text-green-600")
      this.hidePreview()
    }
  }

  extractVideoId(url) {
    try {
      const parsed = new URL(url)
      if (parsed.hostname.includes("youtu.be")) {
        return parsed.pathname.slice(1)
      }
      if (parsed.hostname.includes("youtube.com")) {
        return parsed.searchParams.get("v")
      }
    } catch {
      return null
    }
    return null
  }

  showPreview(videoId) {
    const thumbnailUrl = `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`
    this.thumbnailTarget.src = thumbnailUrl
    this.previewTarget.classList.remove("hidden")
  }

  hidePreview() {
    this.previewTarget.classList.add("hidden")
  }
}
