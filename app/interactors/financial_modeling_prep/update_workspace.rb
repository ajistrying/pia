class FinancialModelingPrep::UpdateWorkspace
  include Interactor

  def call
    # TODO: Implement actual update logic
    # For now, just update the timestamp
    context.workspace.update(last_successful_update: Time.current)
    
    # Simulate some processing time as requested
    sleep 2 if Rails.env.development?
  end
end 