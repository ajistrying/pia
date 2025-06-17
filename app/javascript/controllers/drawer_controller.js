import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["content", "icon"];

	connect() {
		// Set initial state based on content visibility
		this.updateIcon();
	}

	toggle(event) {
		event.preventDefault();
		event.stopPropagation(); // Prevent event bubbling to parent drawers

		const content = this.contentTarget;

		if (content.classList.contains("is-hidden")) {
			// Expand
			content.classList.remove("is-hidden");
			content.style.maxHeight = "none";
			content.style.opacity = "1";

			// Get the actual height after removing hidden class
			const height = content.scrollHeight;
			content.style.maxHeight = "0";

			// Force reflow then animate to full height
			content.offsetHeight;
			content.style.transition = "max-height 0.3s ease-out, opacity 0.3s ease-out";
			content.style.maxHeight = height + "px";

			// After animation, set to auto for dynamic content
			setTimeout(() => {
				content.style.maxHeight = "auto";
			}, 300);
		} else {
			// Collapse
			const height = content.scrollHeight;
			content.style.maxHeight = height + "px";
			content.style.transition = "max-height 0.3s ease-in, opacity 0.3s ease-in";

			// Force reflow then animate to 0
			content.offsetHeight;
			content.style.maxHeight = "0";
			content.style.opacity = "0";

			setTimeout(() => {
				content.classList.add("is-hidden");
				content.style.transition = "";
			}, 300);
		}

		this.updateIcon();
	}

	updateIcon() {
		const content = this.contentTarget;
		const icon = this.iconTarget;

		if (content.classList.contains("is-hidden")) {
			icon.innerHTML = '<i class="fas fa-chevron-down"></i>';
		} else {
			icon.innerHTML = '<i class="fas fa-chevron-up"></i>';
		}
	}
}
