class ProcessEnterpriseValueJob < ApplicationJob
  queue_as :data_processing
  
  def perform(workspace_id)
    result = FinancialModelingPrep::ProcessEnterpriseValue.call(
      company_workspace_id: workspace_id
    )
    
    # Update progress tracker
    tracker = WorkspaceUpdateTracker.new(workspace_id)
    
    if result.success?
      tracker.mark_task_complete('enterprise_value')
      
      workspace = CompanyWorkspace.find(workspace_id)
      Turbo::StreamsChannel.broadcast_replace_to(
        "workspace_#{workspace.id}",
        target: "enterprise-value-section",
        partial: "company_workspaces/enterprise_value",
        locals: { workspace: workspace }
      )
    else
      Rails.logger.error("Error processing enterprise value: #{result.failure}")
    end
  end
end