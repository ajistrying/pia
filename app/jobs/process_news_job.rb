class ProcessNewsJob < ApplicationJob
  queue_as :data_processing
  
  def perform(workspace_id)
    result = FinancialModelingPrep::ProcessNews.call(
      company_workspace_id: workspace_id
    )
    
    # Update progress tracker
    tracker = WorkspaceUpdateTracker.new(workspace_id)
    
    if result.success?
      tracker.mark_task_complete('news')
      
      workspace = CompanyWorkspace.find(workspace_id)
      Turbo::StreamsChannel.broadcast_replace_to(
        "workspace_#{workspace.id}",
        target: "news-section",
        partial: "company_workspaces/news",
        locals: { workspace: workspace }
      )
    else
      Rails.logger.error("Error processing news: #{result.failure}")
    end
  end
end