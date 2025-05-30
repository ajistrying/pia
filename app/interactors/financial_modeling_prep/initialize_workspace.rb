class FinancialModelingPrep::InitializeWorkspace
  include Interactor::Organizer

  # TODO: this is... a lot, might be better to split this up further into sub organizers, especially if I fetch and then summarize each piece of data
  # organize [
  #   FinancialModelingPrep::FetchCompanyProfile,
  #   FinancialModelingPrep::FetchSecFilings,
  #   FinancialModelingPrep::FetchEarningsCalls,
  #   FinancialModelingPrep::FetchKeyRatios,
  #   FinancialModelingPrep::FetchFinancialStatements,
  #   FinancialModelingPrep::FetchNewsPieces,
  #   FinancialModelingPrep::FetchResearchReports
  # ]

  organize FinancialModelingPrep::FinalizeWorkspaceInitialization
end