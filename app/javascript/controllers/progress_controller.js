import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // The progress bar is updated via Turbo Streams
    // This controller can add client-side animations or behaviors
  }
}
