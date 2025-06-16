require "test_helper"

class FinalizeWorkspaceUpdateJobTest < ActiveJob::TestCase
  setup do
    @workspace = CompanyWorkspace.create!(
      company_symbol: "AAPL",
      company_name: "Apple Inc.",
      processing_status: 'processing',
      last_update_started_at: Time.current
    )
  end

  test "should not finalize if workspace is already completed" do
    @workspace.update!(processing_status: 'completed', last_successful_update: 1.hour.ago)
    original_update_time = @workspace.last_successful_update
    
    FinalizeWorkspaceUpdateJob.perform_now(@workspace.id)
    
    assert_equal original_update_time, @workspace.reload.last_successful_update
  end

  test "should reschedule if not all tasks are complete" do
    # Don't mark any tasks as complete
    
    assert_enqueued_jobs 1, only: FinalizeWorkspaceUpdateJob do
      FinalizeWorkspaceUpdateJob.perform_now(@workspace.id)
    end
    
    # Workspace should still be processing
    assert_equal 'processing', @workspace.reload.processing_status
  end

  test "should finalize when all tasks are complete" do
    # Mark all tasks as complete using the tracker (database + cache)
    tracker = WorkspaceUpdateTracker.new(@workspace.id)
    WorkspaceUpdateTracker::TASK_TYPES.each do |task_type|
      tracker.mark_task_complete(task_type)
    end
    
    FinalizeWorkspaceUpdateJob.perform_now(@workspace.id)
    
    @workspace.reload
    assert_equal 'completed', @workspace.processing_status
    assert_equal 100, @workspace.progress_percentage
    assert_not_nil @workspace.last_successful_update
  end

  test "should use database locking to prevent race conditions" do
    # Mark all tasks as complete using the tracker
    tracker = WorkspaceUpdateTracker.new(@workspace.id)
    WorkspaceUpdateTracker::TASK_TYPES.each do |task_type|
      tracker.mark_task_complete(task_type)
    end
    
    # Simulate concurrent finalization attempts
    threads = []
    results = []
    
    5.times do
      threads << Thread.new do
        begin
          FinalizeWorkspaceUpdateJob.perform_now(@workspace.id)
          results << :success
        rescue => e
          results << e.message
        end
      end
    end
    
    threads.each(&:join)
    
    # Only one should succeed in updating the workspace
    @workspace.reload
    assert_equal 'completed', @workspace.processing_status
    assert results.count(:success) >= 1, "At least one finalization should succeed"
  end
end 