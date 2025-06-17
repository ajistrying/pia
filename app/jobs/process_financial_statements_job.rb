class ProcessFinancialStatementsJob < ApplicationJob
  queue_as :data_processing
  
  def perform(workspace_id)
    result = FinancialModelingPrep::ProcessFinancialStatements.call(
      company_workspace_id: workspace_id
    )
    
    # Update progress tracker
    tracker = WorkspaceUpdateTracker.new(workspace_id)
    
    if result.success?
      tracker.mark_task_complete('financial_statements')
    else
      Rails.logger.error("Error processing financial statements: #{result.failure}")
    end
  end
end