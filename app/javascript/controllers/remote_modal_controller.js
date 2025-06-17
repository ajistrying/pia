import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="remote-modal"
export default class extends Controller {
	connect() {
		this.element.showModal();
	}

	close() {
		this.element.close();
	}

	// Close modal when clicking outside content area
	backdropClick(event) {
		if (event.target === this.element) {
			this.close();
		}
	}
}
