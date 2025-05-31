class UpdateWorkspaceJob < ApplicationJob
  queue_as :default

  def perform(workspace_id)
    workspace = CompanyWorkspace.find(workspace_id)
    
    result = FinancialModelingPrep::UpdateWorkspace.call(workspace: workspace)
    
    if result.success?
      # Broadcast the updated content
      Turbo::StreamsChannel.broadcast_replace_to(
        "workspace_#{workspace.id}",
        target: "workspace-content",
        partial: "company_workspaces/workspace_content",
        locals: { workspace: workspace }
      )
    else
      # Broadcast error state
      Turbo::StreamsChannel.broadcast_replace_to(
        "workspace_#{workspace.id}",
        target: "workspace-content",
        partial: "shared/error",
        locals: { error: result.error }
      )
    end
  end
end 