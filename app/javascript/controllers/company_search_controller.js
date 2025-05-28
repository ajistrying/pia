import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
	static targets = ["input", "results"];

	connect() {
		this.timeout = null;
		this.inputTarget.value = "";
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
					});
			} else {
				// Clear results if query is empty
				if (this.hasResultsTarget) {
					this.resultsTarget.innerHTML = "";
				}
			}
		}, 2000); // 2 second delay
	}

	disconnect() {
		clearTimeout(this.timeout);
	}
}
