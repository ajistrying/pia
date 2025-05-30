import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
	static targets = ["input", "results"];

	connect() {
		this.timeout = null;
		this.inputTarget.value = "";
		// Hide results on connect
		if (this.hasResultsTarget) {
			this.resultsTarget.style.display = "none";
		}

		// Add event listeners for closing results
		this.handleOutsideClick = this.handleOutsideClick.bind(this);
		this.handleEscapeKey = this.handleEscapeKey.bind(this);
		document.addEventListener("click", this.handleOutsideClick);
		document.addEventListener("keydown", this.handleEscapeKey);
	}

	search() {
		// Clear any existing timeout
		clearTimeout(this.timeout);

		// Set a new timeout for 2 seconds
		this.timeout = setTimeout(() => {
			const query = this.inputTarget.value.trim();

			if (query.length > 0) {
				// Make the search request using Turbo
				const url = `/company_search/search?query=${encodeURIComponent(query)}`;

				fetch(url, {
					method: "GET",
					headers: {
						Accept: "text/vnd.turbo-stream.html",
						"X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
					},
				})
					.then((response) => response.text())
					.then((html) => {
						Turbo.renderStreamMessage(html);
						// Show results container after rendering
						if (this.hasResultsTarget) {
							this.resultsTarget.style.display = "block";
						}
					});
			} else {
				// Clear results if query is empty
				if (this.hasResultsTarget) {
					this.resultsTarget.innerHTML = "";
					this.resultsTarget.style.display = "none";
				}
			}
		}, 2000); // 2 second delay
	}

	handleOutsideClick(event) {
		// Close results if clicking outside the search container
		if (!this.element.contains(event.target) && this.hasResultsTarget) {
			this.resultsTarget.style.display = "none";
		}
	}

	handleEscapeKey(event) {
		// Close results on Escape key
		if (event.key === "Escape" && this.hasResultsTarget) {
			this.resultsTarget.style.display = "none";
			this.inputTarget.blur(); // Remove focus from input
		}
	}

	disconnect() {
		clearTimeout(this.timeout);
		// Remove event listeners
		document.removeEventListener("click", this.handleOutsideClick);
		document.removeEventListener("keydown", this.handleEscapeKey);
	}
}
