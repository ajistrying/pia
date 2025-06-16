module ApplicationHelper
  def workspace_task_completed?(workspace_id, task_type)
    # Try cache first
    begin
      cache_result = Rails.cache.read("workspace_#{workspace_id}_task_#{task_type}")
      return true if cache_result.present?
    rescue => e
      Rails.logger.warn "Cache read failed for workspace #{workspace_id}, task #{task_type}: #{e.message}"
    end
    
    # Fallback to database
    WorkspaceTaskCompletion.exists?(
      company_workspace_id: workspace_id,
      task_type: task_type
    )
  end
end
