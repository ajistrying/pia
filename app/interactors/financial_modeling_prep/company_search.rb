class FinancialModelingPrep::CompanySearch < FinancialModelingPrep::BaseInteractor
  required_context :query

  def call
    context.url = "https://financialmodelingprep.com/stable/search-symbol?query=#{context.query}&exchange=NASDAQ&limit=10"
    super
  end
end