import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = {
    shortenedUrl: String,
    clicksPath: String,
  }

  static targets = ["clicks", "unique", "firstClicked", "lastClicked", "dayBar"]

  connect() {
    this.displayedClicks = Number(this.hasClicksTarget ? this.clicksTarget.textContent : 0)
    this.displayedUnique = Number(this.hasUniqueTarget ? this.uniqueTarget.textContent : 0)
    this.pollTimer = null

    this.subscription = consumer.subscriptions.create(
      { channel: "ClickChannel", shortened_url: this.shortenedUrlValue },
      {
        connected: () => {
          this.stopPolling()
          this.subscription.perform("sync")
          this.fetchCounts()
        },
        disconnected: () => this.startPolling(),
        rejected: () => this.startPolling(),
        received: (data) => this.applyCounts(data),
      }
    )

    this.visibilityHandler = () => {
      if (document.visibilityState === "visible") {
        this.fetchCounts()
        this.subscription?.perform("sync")
      }
    }
    document.addEventListener("visibilitychange", this.visibilityHandler)
  }

  disconnect() {
    this.stopPolling()
    document.removeEventListener("visibilitychange", this.visibilityHandler)
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  applyCounts({ click_count, unique_clicks, first_clicked_at, last_clicked_at, clicks_by_day } = {}) {
    if (typeof click_count === "number" && click_count > this.displayedClicks) {
      this.displayedClicks = click_count
      if (this.hasClicksTarget) this.clicksTarget.textContent = String(this.displayedClicks)
    }

    if (typeof unique_clicks === "number" && unique_clicks > this.displayedUnique) {
      this.displayedUnique = unique_clicks
      if (this.hasUniqueTarget) this.uniqueTarget.textContent = String(this.displayedUnique)
    }

    if (first_clicked_at && this.hasFirstClickedTarget) {
      this.firstClickedTarget.textContent = this.formatTimestamp(first_clicked_at)
      this.firstClickedTarget.dateTime = first_clicked_at
    }

    if (last_clicked_at && this.hasLastClickedTarget) {
      this.lastClickedTarget.textContent = this.formatTimestamp(last_clicked_at)
      this.lastClickedTarget.dateTime = last_clicked_at
    }

    if (Array.isArray(clicks_by_day)) {
      this.updateDayBars(clicks_by_day)
    }
  }

  updateDayBars(days) {
    if (!this.hasDayBarTarget) return

    const max = Math.max(1, ...days.map((d) => Number(d.count) || 0))
    this.dayBarTargets.forEach((el, index) => {
      const day = days[index]
      if (!day) return
      const count = Number(day.count) || 0
      const pct = Math.round((count / max) * 100)
      el.style.setProperty("--bar-height", `${pct}%`)
      el.dataset.count = String(count)
      el.setAttribute("title", `${day.date}: ${count}`)
      const label = el.querySelector("[data-count-label]")
      if (label) label.textContent = String(count)
    })
  }

  formatTimestamp(value) {
    try {
      return new Date(value).toLocaleString()
    } catch (_error) {
      return value
    }
  }

  async fetchCounts() {
    if (!this.clicksPathValue) return

    try {
      const response = await fetch(this.clicksPathValue, {
        headers: { Accept: "application/json" },
        credentials: "same-origin",
      })
      if (!response.ok) return
      this.applyCounts(await response.json())
    } catch (_error) {
      // Keep last known counts; poll/WS will retry.
    }
  }

  startPolling() {
    if (this.pollTimer) return
    this.pollTimer = window.setInterval(() => this.fetchCounts(), 4000)
  }

  stopPolling() {
    if (!this.pollTimer) return
    window.clearInterval(this.pollTimer)
    this.pollTimer = null
  }
}
