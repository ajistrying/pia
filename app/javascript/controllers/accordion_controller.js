import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["toggle", "content", "icon"];
	static values = { expanded: Boolean };

	connect() {
		// Set initial state based on expanded value
		this.updateDisplay();
	}

	toggle() {
		this.expandedValue = !this.expandedValue;
		this.updateDisplay();
	}

	updateDisplay() {
		this.contentTargets.forEach((content) => {
			if (this.expandedValue) {
				content.classList.remove("hidden");
				content.classList.add("block");
			} else {
				content.classList.remove("block");
				content.classList.add("hidden");
			}
		});

		this.iconTargets.forEach((icon) => {
			if (this.expandedValue) {
				icon.classList.remove("rotate-0");
				icon.classList.add("rotate-90");
			} else {
				icon.classList.remove("rotate-90");
				icon.classList.add("rotate-0");
			}
		});
	}
}
