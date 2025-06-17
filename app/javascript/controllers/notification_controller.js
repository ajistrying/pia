import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="notification"
export default class extends Controller {
	connect() {
		// Auto-dismiss success notifications after 10 seconds
		if (this.element.classList.contains("bg-green-50")) {
			setTimeout(() => {
				this.dismiss();
			}, 10000);
		}
	}

	dismiss() {
		this.element.style.opacity = "0";
		this.element.style.transform = "translateY(-10px)";
		this.element.style.transition = "all 0.3s ease";

		setTimeout(() => {
			this.element.remove();
		}, 300);
	}

	// Action for delete button
	delete() {
		this.dismiss();
	}
}
