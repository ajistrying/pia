class CompanySearchController < ApplicationController
  def index
    @workspaces = CompanyWorkspace.all
  end

  def search
    @query = params[:query]
    
    if @query.present?
      result = FinancialModelingPrep::CompanySearch.call(query: @query)

      if result.success?    
        @error = nil
        @companies = result.response_result
        
        # Batch check for existing workspaces
        existing_workspaces = CompanyWorkspace.where(
          company_symbol: @companies.map { |c| c["symbol"] },
          company_name: @companies.map { |c| c["name"] }
        ).pluck(:company_symbol, :company_name)
        
        @existing_workspaces = existing_workspaces.map { |symbol, name| [symbol, name] }.to_h
      else
        @error = result.error
      end
    else
      @error = "Please enter a company symbol"
    end

    respond_to do |format|
      format.turbo_stream
    end
  end
end