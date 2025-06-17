class SecFilingsController < ApplicationController
  before_action :set_company_workspace
  before_action :set_sec_filing

  def summary
    if @sec_filing.summary.present?
      render partial: 'sec_filings/summary', locals: { sec_filing: @sec_filing }
    else
      render partial: 'sec_filings/no_summary'
    end
  end

  def destroy
    @sec_filing.destroy
    redirect_back(fallback_location: @company_workspace)
  end

  private

  def set_company_workspace
    @company_workspace = CompanyWorkspace.find(params[:company_workspace_id])
  end

  def set_sec_filing
    @sec_filing = @company_workspace.sec_filings.find(params[:id])
  end
end