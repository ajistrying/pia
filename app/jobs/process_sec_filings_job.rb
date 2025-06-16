class ProcessSecFilingsJob < ApplicationJob
  queue_as :data_processing
  
  def perform(workspace_id)
    result = FinancialModelingPrep::ProcessSecFilings.call(
      company_workspace_id: workspace_id
    )
    
    # Update progress tracker
    tracker = WorkspaceUpdateTracker.new(workspace_id)
    
    if result.success?
      tracker.mark_task_complete('sec_filings')
      
      workspace = CompanyWorkspace.find(workspace_id)
      Turbo::StreamsChannel.broadcast_replace_to(
        "workspace_#{workspace.id}",
        target: "sec-filings-section",
        partial: "company_workspaces/sec_filings",
        locals: { workspace: workspace }
      )
    else
      Rails.logger.error("Error processing SEC filings: #{result.failure}")
    end
  end
end