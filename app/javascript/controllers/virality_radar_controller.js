import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radar", "scoreNumber", "scoreRing", "dimensionBar"]
  static values = {
    scores: Object,
    overall: Number
  }

  connect() {
    this.dimensions = [
      "hook_power", "emotional_resonance", "shareability", "practical_value",
      "storytelling", "novelty", "platform_fit", "controversy"
    ]
    this.cx = 200
    this.cy = 200
    this.maxRadius = 150
    this.numPoints = 8
    this.angleStep = (2 * Math.PI) / this.numPoints

    // Delay slightly to allow DOM to settle after Turbo Stream
    requestAnimationFrame(() => this.animateIn())
  }

  animateIn() {
    this.animateCounter()
    this.animateRing()
    this.animateRadar()
    this.animateBars()
  }

  animateCounter() {
    if (!this.hasScoreNumberTarget) return

    const target = this.overallValue
    const duration = 1500
    const start = performance.now()

    const update = (now) => {
      const elapsed = now - start
      const progress = Math.min(elapsed / duration, 1)
      const eased = this.easeOutCubic(progress)
      this.scoreNumberTarget.textContent = Math.round(target * eased)
      if (progress < 1) requestAnimationFrame(update)
    }

    requestAnimationFrame(update)
  }

  animateRing() {
    if (!this.hasScoreRingTarget) return

    const targetDegrees = (this.overallValue / 100) * 360
    const color = this.scoreColor(this.overallValue)
    const duration = 1500
    const start = performance.now()

    const animate = (now) => {
      const elapsed = now - start
      const progress = Math.min(elapsed / duration, 1)
      const eased = this.easeOutCubic(progress)
      const degrees = eased * targetDegrees
      this.scoreRingTarget.style.background = `conic-gradient(${color} ${degrees}deg, rgba(255,255,255,0.08) ${degrees}deg)`
      if (progress < 1) requestAnimationFrame(animate)
    }

    requestAnimationFrame(animate)
  }

  animateRadar() {
    if (!this.hasRadarTarget) return

    const svg = this.radarTarget
    const polygon = svg.querySelector("[data-radar-polygon]")
    if (!polygon) return

    const duration = 2000
    const start = performance.now()

    const animate = (now) => {
      const elapsed = now - start
      const progress = Math.min(elapsed / duration, 1)
      const eased = this.easeOutCubic(progress)

      const points = this.dimensions.map((dim, i) => {
        const score = (this.scoresValue[dim] || 0) * eased
        const radius = (score / 100) * this.maxRadius
        const angle = i * this.angleStep - Math.PI / 2
        const x = this.cx + radius * Math.cos(angle)
        const y = this.cy + radius * Math.sin(angle)
        return `${x.toFixed(1)},${y.toFixed(1)}`
      }).join(" ")

      polygon.setAttribute("points", points)

      // Animate dots
      this.dimensions.forEach((dim, i) => {
        const dot = svg.querySelector(`[data-dot="${dim}"]`)
        if (!dot) return
        const score = (this.scoresValue[dim] || 0) * eased
        const radius = (score / 100) * this.maxRadius
        const angle = i * this.angleStep - Math.PI / 2
        dot.setAttribute("cx", (this.cx + radius * Math.cos(angle)).toFixed(1))
        dot.setAttribute("cy", (this.cy + radius * Math.sin(angle)).toFixed(1))
        dot.setAttribute("opacity", eased.toFixed(2))
        // Scale dot radius based on score
        dot.setAttribute("r", (3 + (score / 100) * 4).toFixed(1))
      })

      if (progress < 1) requestAnimationFrame(animate)
    }

    requestAnimationFrame(animate)
  }

  animateBars() {
    this.dimensionBarTargets.forEach(bar => {
      const dim = bar.dataset.dimension
      const score = this.scoresValue[dim] || 0
      // Delay to let radar animation get ahead
      setTimeout(() => {
        bar.style.width = `${score}%`
      }, 500)
    })
  }

  scoreColor(score) {
    if (score >= 70) return "#10b981"  // emerald
    if (score >= 40) return "#f59e0b"  // amber
    return "#ef4444"                    // red
  }

  easeOutCubic(t) {
    return 1 - Math.pow(1 - t, 3)
  }
}
