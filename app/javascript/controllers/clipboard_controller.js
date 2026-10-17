import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    const value = this.textValue || this.element.dataset.clipboardText
    if (!value) return

    navigator.clipboard.writeText(value).then(() => {
      const toastEl = document.getElementById("liveToast")
      if (toastEl && window.bootstrap?.Toast) {
        new window.bootstrap.Toast(toastEl).show()
      }
    })
  }
}
