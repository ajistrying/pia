class ProcessKeyRatiosJob < ApplicationJob
  queue_as :data_processing
  
  def perform(workspace_id)
    result = FinancialModelingPrep::ProcessKeyRatios.call(
      company_workspace_id: workspace_id
    )
    
    # Update progress tracker
    tracker = WorkspaceUpdateTracker.new(workspace_id)
    
    if result.success?
      tracker.mark_task_complete('key_ratios')
    else
      Rails.logger.error("Error processing key ratios: #{result.failure}")
    end
  end
end