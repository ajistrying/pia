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
    else
      Rails.logger.error("Error processing SEC filings: #{result.failure}")
    end
  end
end