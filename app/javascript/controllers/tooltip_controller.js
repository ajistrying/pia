import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["content"];

	show() {
		this.contentTarget.classList.remove("opacity-0", "pointer-events-none");
		this.contentTarget.classList.add("opacity-100");
	}

	hide() {
		this.contentTarget.classList.add("opacity-0", "pointer-events-none");
		this.contentTarget.classList.remove("opacity-100");
	}
}
