import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["tab", "content"];
	static values = { workspaceId: Number };

	connect() {
		this.showActiveContent();
	}

	switch(event) {
		event.preventDefault();

		// Remove active class from all tabs
		this.tabTargets.forEach((tab) => {
			tab.classList.remove("border-blue-500", "text-blue-600");
			tab.classList.add("border-transparent", "text-gray-500");
		});

		// Add active class to clicked tab
		const clickedTab = event.currentTarget;
		clickedTab.classList.remove("border-transparent", "text-gray-500");
		clickedTab.classList.add("border-blue-500", "text-blue-600");

		// Get tab content name
		const targetContent = clickedTab.dataset.tabContent;

		// Show loading state
		this.showLoading();

		// Load content via AJAX
		this.loadTabContent(targetContent);
	}

	showLoading() {
		const contentContainer = document.querySelector("#tab-content-container");
		if (contentContainer) {
			contentContainer.innerHTML = `
        <div class="bg-white shadow-sm rounded-lg p-6 text-center">
          <div class="text-4xl text-gray-300 mb-4">
            <i class="fas fa-spinner fa-spin"></i>
          </div>
          <p class="text-lg font-medium text-gray-400">Loading...</p>
        </div>
      `;
		}
	}

	async loadTabContent(tabName) {
		try {
			const response = await fetch(
				`/company_workspaces/${this.workspaceIdValue}/workspace_content?tab=${tabName}`,
				{
					headers: {
						Accept: "text/html",
						"X-Requested-With": "XMLHttpRequest",
					},
				}
			);

			if (response.ok) {
				const html = await response.text();
				const contentContainer = document.querySelector("#tab-content-container");
				if (contentContainer) {
					contentContainer.innerHTML = html;
				}
			} else {
				this.showError();
			}
		} catch (error) {
			console.error("Error loading tab content:", error);
			this.showError();
		}
	}

	showError() {
		const contentContainer = document.querySelector("#tab-content-container");
		if (contentContainer) {
			contentContainer.innerHTML = `
        <div class="bg-white shadow-sm rounded-lg p-6 text-center">
          <div class="text-4xl text-red-500 mb-4">
            <i class="fas fa-exclamation-triangle"></i>
          </div>
          <p class="text-lg font-medium text-gray-400">Error Loading Content</p>
          <p class="text-base text-gray-500">Please try again or refresh the page</p>
        </div>
      `;
		}
	}

	showActiveContent() {
		// Load overview tab by default
		this.loadTabContent("overview");
	}
}
