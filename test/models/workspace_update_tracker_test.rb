require "test_helper"

class WorkspaceUpdateTrackerTest < ActiveSupport::TestCase
  setup do
    @workspace = CompanyWorkspace.create!(
      company_symbol: "AAPL",
      company_name: "Apple Inc.",
      processing_status: 'processing'
    )
    @tracker = WorkspaceUpdateTracker.new(@workspace.id)
  end

  test "should mark task as complete in both database and cache" do
    @tracker.mark_task_complete('sec_filings')
    
    # Check database
    assert WorkspaceTaskCompletion.exists?(
      company_workspace_id: @workspace.id,
      task_type: 'sec_filings'
    )
    
    # Check cache
    assert Rails.cache.read("workspace_#{@workspace.id}_task_sec_filings").present?
  end

  test "should fallback to database when cache fails" do
    # Create database record directly
    WorkspaceTaskCompletion.create!(
      company_workspace_id: @workspace.id,
      task_type: 'earnings_calls',
      completed_at: Time.current
    )
    
    # Clear cache
    Rails.cache.delete("workspace_#{@workspace.id}_task_earnings_calls")
    
    # Should still count as completed due to database fallback
    assert_equal 1, @tracker.send(:completed_task_count)
  end

  test "should rebuild cache from database when needed" do
    # Create database records
    WorkspaceUpdateTracker::TASK_TYPES.first(3).each do |task_type|
      WorkspaceTaskCompletion.create!(
        company_workspace_id: @workspace.id,
        task_type: task_type,
        completed_at: Time.current
      )
    end
    
    # Clear all cache
    WorkspaceUpdateTracker::TASK_TYPES.each do |task_type|
      Rails.cache.delete("workspace_#{@workspace.id}_task_#{task_type}")
    end
    
    # This should trigger cache rebuild
    count = @tracker.send(:completed_task_count)
    assert_equal 3, count
    
    # Verify cache was rebuilt
    cache_count = WorkspaceUpdateTracker::TASK_TYPES.count do |task|
      Rails.cache.read("workspace_#{@workspace.id}_task_#{task}").present?
    end
    assert_equal 3, cache_count
  end

  test "should clean up both database and cache on finalization" do
    # Mark some tasks complete
    @tracker.mark_task_complete('sec_filings')
    @tracker.mark_task_complete('earnings_calls')
    
    # Verify they exist
    assert_equal 2, WorkspaceTaskCompletion.where(company_workspace_id: @workspace.id).count
    
    # Mark all tasks complete to trigger finalization
    WorkspaceUpdateTracker::TASK_TYPES.each do |task_type|
      @tracker.mark_task_complete(task_type)
    end
    
    # Verify cleanup
    assert_equal 0, WorkspaceTaskCompletion.where(company_workspace_id: @workspace.id).count
    
    # Verify cache cleanup
    cache_entries = WorkspaceUpdateTracker::TASK_TYPES.count do |task|
      Rails.cache.read("workspace_#{@workspace.id}_task_#{task}").present?
    end
    assert_equal 0, cache_entries
  end
end 