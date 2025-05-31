class InitializeWorkspaceJob < ApplicationJob
  queue_as :default

  def perform(workspace_id)
    workspace = CompanyWorkspace.find(workspace_id)
    
    result = FinancialModelingPrep::InitializeWorkspace.call(workspace: workspace)
    
    if result.success?
      # Broadcast the completed content via Turbo Streams
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