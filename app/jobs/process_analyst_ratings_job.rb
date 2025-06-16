class ProcessAnalystRatingsJob < ApplicationJob
  queue_as :data_processing
  
  def perform(workspace_id)
    result = FinancialModelingPrep::ProcessAnalystRatings.call(
      company_workspace_id: workspace_id
    )
    
    # Update progress tracker
    tracker = WorkspaceUpdateTracker.new(workspace_id)
    
    if result.success?
      tracker.mark_task_complete('analyst_ratings')
      
      workspace = CompanyWorkspace.find(workspace_id)
      Turbo::StreamsChannel.broadcast_replace_to(
        "workspace_#{workspace.id}",
        target: "analyst-ratings-section",
        partial: "company_workspaces/analyst_ratings",
        locals: { workspace: workspace }
      )
    else
      Rails.logger.error("Error processing analyst ratings: #{result.failure}")
    end
  end
end