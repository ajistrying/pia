class ParallelWorkspaceUpdateJob < ApplicationJob
  queue_as :workspace_updates
  
  def perform(workspace_id)
    workspace = CompanyWorkspace.find(workspace_id)
    
    # Mark update as started
    workspace.update!(
      last_update_started_at: Time.current,
      processing_status: 'processing',
      progress_percentage: 0
    )
    
    # Launch all processing jobs in parallel
    jobs = [
      ProcessSecFilingsJob.perform_later(workspace_id),
      ProcessEarningsCallsJob.perform_later(workspace_id), 
      ProcessFinancialStatementsJob.perform_later(workspace_id),
      ProcessKeyRatiosJob.perform_later(workspace_id),
      ProcessEnterpriseValueJob.perform_later(workspace_id),
      ProcessAnalystRatingsJob.perform_later(workspace_id),
      ProcessNewsJob.perform_later(workspace_id)
    ]
    
    # Schedule finalization job as a safety net
    # It will check task completion status and reschedule if needed
    FinalizeWorkspaceUpdateJob.set(wait: 2.minutes).perform_later(workspace_id)
    
    Rails.logger.info "Launched #{jobs.size} parallel jobs for workspace #{workspace.company_symbol}"
  end
end