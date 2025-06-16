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
      
      workspace = CompanyWorkspace.find(workspace_id)
      Turbo::StreamsChannel.broadcast_replace_to(
        "workspace_#{workspace.id}",
        target: "key-ratios-section",
        partial: "company_workspaces/key_ratios",
        locals: { workspace: workspace }
      )
    else
      Rails.logger.error("Error processing key ratios: #{result.failure}")
    end
  end
end