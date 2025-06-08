class FinancialModelingPrep::UpdateWorkspace
  include Organizer

  organize(
    FinancialModelingPrep::ProcessSecFilings,
    FinancialModelingPrep::ProcessEarningsCalls,
    FinancialModelingPrep::ProcessAnalystRatings,
    FinancialModelingPrep::ProcessNews,
    FinancialModelingPrep::FinalizeWorkspaceUpdate,
  )
end 