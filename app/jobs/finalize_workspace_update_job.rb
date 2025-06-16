class FinalizeWorkspaceUpdateJob < ApplicationJob
  queue_as :critical
  
  def perform(workspace_id, job_ids = [])
    workspace = CompanyWorkspace.find(workspace_id)
    
    # Don't finalize if already completed
    return if workspace.processing_status == 'completed'
    
    # Check if all tasks are actually complete using the robust tracker
    tracker = WorkspaceUpdateTracker.new(workspace_id)
    unless tracker.all_tasks_complete?
      # If not all tasks are complete, wait a bit and try again
      FinalizeWorkspaceUpdateJob.set(wait: 30.seconds).perform_later(workspace_id)
      return
    end
    
    # All tasks are complete - finalize the workspace
    finalize_workspace(workspace)
    
    Rails.logger.info "Completed workspace update for #{workspace.company_symbol} via FinalizeWorkspaceUpdateJob"
  end
  
  private
  
  def finalize_workspace(workspace)
    # Use database-level locking to prevent race conditions
    workspace.with_lock do
      # Double-check status after acquiring lock
      return if workspace.processing_status == 'completed'
      
      # Update workspace completion status
      workspace.update!(
        last_successful_update: Time.current,
        processing_status: 'completed',
        progress_percentage: 100
      )
    end
    
    # Clear any cached progress data
    clear_progress_cache(workspace.id)
    
    # Broadcast final completed workspace
    Turbo::StreamsChannel.broadcast_replace_to(
      "workspace_#{workspace.id}",
      target: "workspace-content",
      partial: "company_workspaces/workspace_content",
      locals: { workspace: workspace }
    )
    
    # Broadcast completion notification
    Turbo::StreamsChannel.broadcast_replace_to(
      "workspace_#{workspace.id}",
      target: "progress-indicator",
      partial: "company_workspaces/completion_notification",
      locals: { workspace: workspace }
    )
  end
  
  def clear_progress_cache(workspace_id)
    # Clear cache
    WorkspaceUpdateTracker::TASK_TYPES.each do |task|
      Rails.cache.delete("workspace_#{workspace_id}_task_#{task}")
    end
    
    # Clear database task completion records
    WorkspaceTaskCompletion.where(
      company_workspace_id: workspace_id,
      task_type: WorkspaceUpdateTracker::TASK_TYPES
    ).delete_all
  end
end