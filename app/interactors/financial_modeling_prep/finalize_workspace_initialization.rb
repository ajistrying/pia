class FinancialModelingPrep::FinalizeWorkspaceInitialization
  include Interactor

  def call
    context.workspace.update(initialized_at: Time.current)
    # TODO: More to come here
  end
end