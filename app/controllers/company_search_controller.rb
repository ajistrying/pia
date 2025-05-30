class CompanySearchController < ApplicationController
  def index
    # TODO: After implementing initialization, we can remove this hardcoded list
    # @workspaces = CompanyWorkspace.all
    @workspaces = [
      OpenStruct.new(company_name: "Apple Inc.", company_symbol: "AAPL"),
      OpenStruct.new(company_name: "Tesla Inc.", company_symbol: "TSLA"),
      OpenStruct.new(company_name: "Alphabet Inc.", company_symbol: "GOOG"),
      OpenStruct.new(company_name: "Microsoft Corp.", company_symbol: "MSFT")
    ]
  end

  def search
    @query = params[:query]
    
    if @query.present?
      result = FinancialModelingPrep::CompanySearch.call(query: @query)

      if result.success?    
        @error = nil
        @companies = result.response_result
      else
        @error = result.error
      end
    else
      @error = "Please enter a company symbol"
    end

    # @companies = [
    #   {
    #     "symbol" => "AAPL",
    #     "name" => "Apple Inc."
    #   },
    #   {
    #     "symbol" => "TSLA",
    #     "name" => "Tesla Inc."
    #   },
    #   {
    #     "symbol" => "GOOG",
    #     "name" => "Alphabet Inc."
    #   },
    #   {
    #     "symbol" => "MSFT",
    #     "name" => "Microsoft Corp."
    #   }
    # ]

    respond_to do |format|
      format.turbo_stream
    end
  end
end