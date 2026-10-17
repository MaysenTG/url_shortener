import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "originalUrl",
    "customCode",
    "originalError",
    "customError",
    "submit",
    "more",
  ]

  static values = {
    validateUrl: String,
  }

  connect() {
    this.debounceTimers = {}
    this.fieldValidity = {
      original_url: true,
      custom_code: true,
    }
    this.updateSubmitState()
  }

  disconnect() {
    Object.values(this.debounceTimers).forEach((timer) => window.clearTimeout(timer))
  }

  validateOriginal() {
    this.queueValidation("original_url", this.originalUrlTarget.value, this.originalErrorTarget, this.originalUrlTarget)
  }

  validateCustom() {
    if (this.hasMoreTarget) this.moreTarget.open = true
    this.queueValidation("custom_code", this.customCodeTarget.value, this.customErrorTarget, this.customCodeTarget)
  }

  queueValidation(field, value, errorEl, inputEl) {
    window.clearTimeout(this.debounceTimers[field])
    this.debounceTimers[field] = window.setTimeout(() => {
      this.runValidation(field, value, errorEl, inputEl)
    }, 320)
  }

  async runValidation(field, value, errorEl, inputEl) {
    const trimmed = value.trim()

    // Empty custom code is optional and valid.
    if (field === "custom_code" && trimmed === "") {
      this.clearFieldError(field, errorEl, inputEl)
      return
    }

    if (field === "original_url" && trimmed === "") {
      this.setFieldError(field, errorEl, inputEl, ["Enter a URL to shorten"])
      return
    }

    try {
      const url = new URL(this.validateUrlValue, window.location.origin)
      url.searchParams.set("field", field)
      url.searchParams.set("value", trimmed)

      const response = await fetch(url.toString(), {
        headers: { Accept: "application/json" },
        credentials: "same-origin",
      })
      if (!response.ok) throw new Error(`validation failed (${response.status})`)

      const data = await response.json()
      if (data.valid) {
        this.clearFieldError(field, errorEl, inputEl)
      } else {
        this.setFieldError(field, errorEl, inputEl, data.errors || ["Invalid value"])
      }
    } catch (error) {
      console.error("URL validation request failed", error)
    }
  }

  setFieldError(field, errorEl, inputEl, messages) {
    this.fieldValidity[field] = false
    errorEl.hidden = false
    errorEl.textContent = messages[0]
    inputEl.classList.add("is-invalid")
    inputEl.classList.remove("is-valid")
    inputEl.setAttribute("aria-invalid", "true")
    this.updateSubmitState()
  }

  clearFieldError(field, errorEl, inputEl) {
    this.fieldValidity[field] = true
    errorEl.hidden = true
    errorEl.textContent = ""
    inputEl.classList.remove("is-invalid")
    inputEl.setAttribute("aria-invalid", "false")
    inputEl.classList.toggle("is-valid", inputEl.value.trim() !== "")
    this.updateSubmitState()
  }

  updateSubmitState() {
    if (!this.hasSubmitTarget) return
    const ok = this.fieldValidity.original_url && this.fieldValidity.custom_code
    this.submitTarget.disabled = !ok
  }

  async ensureValidBeforeSubmit(event) {
    await Promise.all([
      this.runValidation("original_url", this.originalUrlTarget.value, this.originalErrorTarget, this.originalUrlTarget),
      this.hasCustomCodeTarget
        ? this.runValidation("custom_code", this.customCodeTarget.value, this.customErrorTarget, this.customCodeTarget)
        : Promise.resolve(),
    ])

    if (!(this.fieldValidity.original_url && this.fieldValidity.custom_code)) {
      event.preventDefault()
      if (!this.fieldValidity.custom_code && this.hasMoreTarget) this.moreTarget.open = true
      const firstInvalid = this.element.querySelector(".is-invalid")
      firstInvalid?.focus()
    }
  }
}
