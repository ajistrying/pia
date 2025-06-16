require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  setup do
    @workspace = CompanyWorkspace.create!(
      company_symbol: "AAPL", 
      company_name: "Apple Inc."
    )
  end

  test "should return true when task is completed in cache" do
    Rails.cache.write("workspace_#{@workspace.id}_task_sec_filings", { completed: true })
    
    assert workspace_task_completed?(@workspace.id, 'sec_filings')
  end

  test "should return true when task is completed in database but not cache" do
    WorkspaceTaskCompletion.create!(
      company_workspace_id: @workspace.id,
      task_type: 'earnings_calls',
      completed_at: Time.current
    )
    
    # Ensure cache is empty
    Rails.cache.delete("workspace_#{@workspace.id}_task_earnings_calls")
    
    assert workspace_task_completed?(@workspace.id, 'earnings_calls')
  end

  test "should return false when task is not completed in either cache or database" do
    # Ensure cache is empty
    Rails.cache.delete("workspace_#{@workspace.id}_task_financial_statements")
    
    assert_not workspace_task_completed?(@workspace.id, 'financial_statements')
  end

  # Note: Cache error handling is implemented in the helper method
  # but difficult to test in this test framework without additional mocking gems
end 