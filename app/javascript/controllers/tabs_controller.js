import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content"]
  static values = { workspaceId: Number }
  
  connect() {
    this.showActiveContent()
  }
  
  switch(event) {
    event.preventDefault()
    
    // Remove active class from all tabs
    this.tabTargets.forEach(tab => {
      tab.classList.remove("is-active")
    })
    
    // Add active class to clicked tab
    const clickedTab = event.currentTarget.closest("li")
    clickedTab.classList.add("is-active")
    
    // Get tab content name
    const targetContent = clickedTab.dataset.tabContent
    
    // Show loading state
    this.showLoading()
    
    // Load content via AJAX
    this.loadTabContent(targetContent)
  }
  
  showLoading() {
    const contentContainer = document.querySelector("#tab-content-container")
    if (contentContainer) {
      contentContainer.innerHTML = `
        <div class="box has-text-centered p-6">
          <div class="is-size-1 has-text-grey-lighter mb-4">
            <i class="fas fa-spinner fa-spin"></i>
          </div>
          <p class="title is-5 has-text-grey-light">Loading...</p>
        </div>
      `
    }
  }
  
  async loadTabContent(tabName) {
    try {
      const response = await fetch(`/company_workspaces/${this.workspaceIdValue}/workspace_content?tab=${tabName}`, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const html = await response.text()
        const contentContainer = document.querySelector("#tab-content-container")
        if (contentContainer) {
          contentContainer.innerHTML = html
        }
      } else {
        this.showError()
      }
    } catch (error) {
      console.error('Error loading tab content:', error)
      this.showError()
    }
  }
  
  showError() {
    const contentContainer = document.querySelector("#tab-content-container")
    if (contentContainer) {
      contentContainer.innerHTML = `
        <div class="box has-text-centered p-6">
          <div class="is-size-1 has-text-danger mb-4">
            <i class="fas fa-exclamation-triangle"></i>
          </div>
          <p class="title is-5 has-text-grey-light">Error Loading Content</p>
          <p class="subtitle is-6 has-text-grey">Please try again or refresh the page</p>
        </div>
      `
    }
  }
  
  showActiveContent() {
    // Load overview tab by default
    this.loadTabContent('overview')
  }
}