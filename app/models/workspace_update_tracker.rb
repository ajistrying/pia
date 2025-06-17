class WorkspaceUpdateTracker
  attr_reader :workspace_id, :total_tasks, :completed_tasks
  
  TASK_TYPES = %w[
    sec_filings
    financial_statements
    key_ratios
    enterprise_value
    analyst_ratings
    news
  ].freeze
  
  def initialize(workspace_id)
    @workspace_id = workspace_id
    @total_tasks = TASK_TYPES.size
    @completed_tasks = 0
  end
  
  def mark_task_complete(task_type)
    return unless TASK_TYPES.include?(task_type.to_s)
    
    # Primary persistence: Database (idempotent)
    WorkspaceTaskCompletion.find_or_create_by(
      company_workspace_id: workspace_id,
      task_type: task_type.to_s
    ) do |completion|
      completion.completed_at = Time.current
    end
    
    # Secondary: Cache for fast reads (with error handling)
    begin
      Rails.cache.write(
        "workspace_#{workspace_id}_task_#{task_type}", 
        { completed: true, timestamp: Time.current.to_i },
        expires_in: 2.hours, # Longer TTL for stability
        race_condition_ttl: 10.seconds # Prevent cache stampedes
      )
    rescue => e
      Rails.logger.warn "Cache write failed for workspace #{workspace_id}, task #{task_type}: #{e.message}"
      # Continue processing - don't fail for cache issues
    end
    
    @completed_tasks = completed_task_count
    broadcast_progress_update
    
    if all_tasks_complete?
      finalize_update
    end
  end
  
  def progress_percentage
    (@completed_tasks.to_f / @total_tasks * 100).round
  end
  
  def all_tasks_complete?
    completed_task_count == total_tasks
  end
  
  private
  
  def completed_task_count
    # Try cache first for performance
    cache_successful = true
    cached_count = 0
    
    begin
      cached_count = TASK_TYPES.count do |task|
        Rails.cache.read("workspace_#{workspace_id}_task_#{task}").present?
      end
    rescue => e
      Rails.logger.warn "Cache read failed for workspace #{workspace_id}: #{e.message}"
      cache_successful = false
    end
    
    # If cache read failed or returned 0 (which might indicate cache miss), 
    # fallback to database
    if !cache_successful || cached_count == 0
      db_count = WorkspaceTaskCompletion.where(
        company_workspace_id: workspace_id, 
        task_type: TASK_TYPES
      ).count
      
      # If database has completions but cache doesn't, rebuild cache
      if db_count > 0 && cached_count == 0
        rebuild_cache_from_database
        return db_count
      end
      
      return db_count
    end
    
    cached_count
  end

  # Rebuild cache from database state (recovery mechanism)
  def rebuild_cache_from_database
    Rails.logger.info "Rebuilding cache from database for workspace #{workspace_id}"
    
    completed_tasks = WorkspaceTaskCompletion.where(
      company_workspace_id: workspace_id,
      task_type: TASK_TYPES
    )
    
    completed_tasks.each do |completion|
      begin
        Rails.cache.write(
          "workspace_#{workspace_id}_task_#{completion.task_type}",
          { completed: true, timestamp: completion.completed_at.to_i },
          expires_in: 2.hours,
          race_condition_ttl: 10.seconds
        )
      rescue => e
        Rails.logger.warn "Failed to rebuild cache for task #{completion.task_type}: #{e.message}"
      end
    end
  end

  def broadcast_progress_update
    workspace = CompanyWorkspace.find(workspace_id)
    
    Turbo::StreamsChannel.broadcast_replace_to(
      "workspace_#{workspace_id}",
      target: "progress-indicator",
      partial: "company_workspaces/progress_indicator",
      locals: { 
        workspace: workspace,
        progress: progress_percentage,
        completed_tasks: @completed_tasks,
        total_tasks: @total_tasks
      }
    )
  end
  
  def finalize_update
    workspace = CompanyWorkspace.find(workspace_id)
    
    # Avoid duplicate finalization - check if already completed
    return if workspace.processing_status == 'completed'
    
    # Use database-level locking to prevent race conditions
    workspace.with_lock do
      # Double-check status after acquiring lock
      return if workspace.processing_status == 'completed'
      
      workspace.update!(
        last_successful_update: Time.current,
        processing_status: 'completed',
        progress_percentage: 100
      )
    end
    
    # Clear both cache and database records
    TASK_TYPES.each do |task|
      Rails.cache.delete("workspace_#{workspace_id}_task_#{task}")
    end
    
    # Clean up database task completion records
    WorkspaceTaskCompletion.where(
      company_workspace_id: workspace_id,
      task_type: TASK_TYPES
    ).delete_all
    
    # Broadcast final completed state
    Turbo::StreamsChannel.broadcast_replace_to(
      "workspace_#{workspace_id}",
      target: "workspace-content",
      partial: "company_workspaces/workspace_content",
      locals: { workspace: workspace }
    )
    
    # Broadcast completion notification to the progress indicator outside the frame
    Turbo::StreamsChannel.broadcast_replace_to(
      "workspace_#{workspace_id}",
      target: "progress-indicator",
      partial: "company_workspaces/completion_notification",
      locals: { workspace: workspace }
    )
    
    Rails.logger.info "Completed workspace update for #{workspace.company_symbol} via WorkspaceUpdateTracker"
  end
end