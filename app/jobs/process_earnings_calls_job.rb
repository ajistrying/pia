class ProcessEarningsCallsJob < ApplicationJob
  queue_as :data_processing
  
  def perform(workspace_id)
    result = FinancialModelingPrep::ProcessEarningsCalls.call(
      company_workspace_id: workspace_id
    )
    
    # Update progress tracker
    tracker = WorkspaceUpdateTracker.new(workspace_id)
    
    if result.success?
      tracker.mark_task_complete('earnings_calls')
      
      workspace = CompanyWorkspace.find(workspace_id)
      Turbo::StreamsChannel.broadcast_replace_to(
        "workspace_#{workspace.id}",
        target: "earnings-calls-section",
        partial: "company_workspaces/earnings_calls",
        locals: { workspace: workspace }
      )
    else
      Rails.logger.error("Error processing earnings calls: #{result.failure}")
    end
  end
end