class FinancialModelingPrep::FinalizeWorkspaceInitialization
  include Interactor

  def call
    # Simulate some processing time as requested
    sleep 3 if Rails.env.development?
    
    context.workspace.update(
      initialized_at: Time.current,
      last_successful_update: Time.current
    )
  end
end